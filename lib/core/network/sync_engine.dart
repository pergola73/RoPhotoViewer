import 'dart:io';
import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:kphoto/core/database/app_database.dart';
import 'package:kphoto/core/network/kdrive_api_service.dart';
import 'package:exif/exif.dart';
import 'package:geocoding/geocoding.dart';

import 'package:kphoto/core/services/ai_tagging_service.dart';

class SyncEngine {
  final KDriveApiService _apiService;
  final AppDatabase _db;
  bool _isSyncing = false;

  SyncEngine(this._apiService, this._db);

  KDriveApiService get apiService => _apiService;

  Future<void> sync(String rootFolderId, {Function(int)? onProgress}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    final aiService = AITaggingService(_db, _apiService);
    debugPrint('Sync: Starten sync vanaf map $rootFolderId...');

    try {
      final localDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory(p.join(localDir.path, 'thumbnails'));
      if (!thumbDir.existsSync()) thumbDir.createSync(recursive: true);

      final List<String> folderQueue = [rootFolderId];
      final Set<String> visitedFolders = {rootFolderId};
      int totalProcessed = 0;
      int totalNew = 0;

      while (folderQueue.isNotEmpty) {
        final currentFolderId = folderQueue.removeAt(0);

        try {
          await for (final batch in _apiService.getChildrenStream(currentFolderId)) {
            List<PhotosCompanion> metadataBuffer = [];
            List<Photo> photosToDownloadInBatch = [];

            for (final item in batch) {
              final name = item['name']?.toString() ?? 'onbekend';
              final fileId = (item['id'] ?? item['file_id'] ?? item['node_id'] ?? item['node']?['id'])?.toString();

              if (fileId == null) continue;

              final type = item['type']?.toString(); 
              final mimeType = item['mime_type']?.toString();
              final bool isFolder = type == 'dir' || type == 'folder' || mimeType == 'application/x-directory' || type == 'node_dir';

              if (isFolder) {
                if (!visitedFolders.contains(fileId)) {
                  visitedFolders.add(fileId);
                  folderQueue.add(fileId);
                }
                continue;
              }

              final bool isImg = _isImage(name) || (mimeType?.startsWith('image/') ?? false);
              final bool isVid = _isVideo(name) || (mimeType?.startsWith('video/') ?? false);

              if (!isImg && !isVid) continue;

              final existing = await _db.getPhotoByKdriveId(fileId);
              if (existing != null) {
                if (existing.localThumbnailPath == null || !File(existing.localThumbnailPath!).existsSync()) {
                  photosToDownloadInBatch.add(existing);
                }
                continue;
              }

              final mediaType = isVid ? 'video' : 'image';
              totalProcessed++;
              
              String? locationName;
              double? lat;
              double? lon;
              final List<String> tags = [];
              final DateTime dateTaken = _extractDate(item);

              final dynamic exif = item['exif'];
              if (exif != null) {
                final dynamic gps = exif['gps'] ?? exif['location']?['gps'];
                if (gps != null) {
                  lat = _toDouble(gps['latitude'] ?? gps['lat']);
                  lon = _toDouble(gps['longitude'] ?? gps['lon']);
                }
                
                locationName = exif['location']?['name']?.toString();
                if (locationName != null && locationName.isNotEmpty) {
                  final locParts = locationName.split(',').map((s) => s.trim().toLowerCase()).where((s) => s.length > 1);
                  tags.addAll(locParts);
                }
              }

              metadataBuffer.add(PhotosCompanion.insert(
                fileName: name,
                kdrivePath: fileId,
                dateTaken: dateTaken,
                aiTags: tags,
                locationName: Value(locationName),
                latitude: Value(lat),
                longitude: Value(lon),
                mediaType: Value(mediaType),
              ));
              totalNew++;
            }

            if (metadataBuffer.isNotEmpty) {
              await _flushMetadata(metadataBuffer);
              for (var m in metadataBuffer) {
                final photo = await _db.getPhotoByKdriveId(m.kdrivePath.value);
                if (photo != null) photosToDownloadInBatch.add(photo);
              }
            }

            if (photosToDownloadInBatch.isNotEmpty) {
              await _downloadThumbnails(photosToDownloadInBatch, thumbDir);
            }

            onProgress?.call(totalProcessed);
          }
        } catch (e) {
          debugPrint('Sync: Fout in map $currentFolderId: $e');
        }
      }

      debugPrint('Sync: Klaar. $totalNew nieuwe media bestanden gevonden.');

    } catch (e, stack) {
      debugPrint('Sync: Fout — $e\n$stack');
    } finally {
      _isSyncing = false;
      debugPrint('Sync: Volledig afgerond.');
    }
  }

  DateTime _extractDate(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? '';
    final dynamic exif = item['exif'];
    
    final dynamic kDriveDate = exif?['date_taken'] ?? exif?['date_time_original'] ?? exif?['date_time'];
    if (kDriveDate != null) {
      DateTime? parsed = _parseAnyDate(kDriveDate);
      if (parsed != null) return parsed;
    }

    final RegExp dateRegex = RegExp(r'(\d{4})(\d{2})(\d{2})');
    final match = dateRegex.firstMatch(name);
    if (match != null) {
      try {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        if (year > 1990 && year < 2100 && month > 0 && month <= 12 && day > 0 && day <= 31) {
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    final dynamic lastMod = item['last_modified'] ?? item['mtime'];
    final dynamic createdAt = item['created_at'];

    DateTime? bestFallback = _parseAnyDate(lastMod) ?? _parseAnyDate(createdAt);
    return bestFallback ?? DateTime.now();
  }

  DateTime? _parseAnyDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      int ts = raw.toInt();
      if (ts > 32503680000) ts = ts ~/ 1000;
      return DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    } else if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  double? _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  Future<void> _downloadThumbnails(List<Photo> photos, Directory thumbDir) async {
    final aiService = AITaggingService(_db, _apiService);
    const int concurrency = 3;
    
    for (int i = 0; i < photos.length; i += concurrency) {
      final chunk = photos.skip(i).take(concurrency);

      await Future.wait(chunk.map((photo) async {
        final localThumbPath = p.join(thumbDir.path, 'thumb_${photo.id}.jpg');
        try {
          await _apiService
              .downloadThumbnail(photo.kdrivePath, localThumbPath)
              .timeout(const Duration(seconds: 45));

          final file = File(localThumbPath);
          if (file.existsSync() && file.lengthSync() > 0) {
            await (_db.update(_db.photos)..where((t) => t.id.equals(photo.id)))
                .write(PhotosCompanion(localThumbnailPath: Value(localThumbPath)));
            
            await updateMetadataFromFile(photo.id, localThumbPath);
            
            final updatedPhoto = await (_db.select(_db.photos)..where((t) => t.id.equals(photo.id))).getSingle();
            unawaited(aiService.processSinglePhoto(updatedPhoto));
          } else {
            if (file.existsSync()) file.deleteSync();
          }
        } catch (e) {
          debugPrint('Sync: Thumbnail verwerking mislukt voor ${photo.fileName}: $e');
        }
      }));
    }
  }

  Future<void> updateMetadataFromFile(int photoId, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;
      
      final data = await readExifFromFile(file);
      if (data.isEmpty) return;

      final String? make = data['Image Make']?.printable;
      final String? model = data['Image Model']?.printable;
      final String? camera = (make != null && model != null) 
          ? (model.contains(make) ? model : '$make $model') 
          : (model ?? make);

      final String? exposure = data['EXIF ExposureTime']?.printable;
      final String? fNumber = data['EXIF FNumber']?.printable;
      final String? iso = data['EXIF ISOSpeedRatings']?.printable;
      final String? focal = data['EXIF FocalLength']?.printable;
      final String? flash = data['EXIF Flash']?.printable;
      final String? lens = data['EXIF LensModel']?.printable ?? data['EXIF LensInfo']?.printable;

      // Extract Keywords
      String? extractedKeywords;
      final xpKeywords = data['Image XPKeywords'];
      final imageDescription = data['Image ImageDescription'];
      final userComment = data['EXIF UserComment'];

      if (xpKeywords != null) {
        try {
          if (xpKeywords.values is List<int>) {
            final values = xpKeywords.values;
            extractedKeywords = String.fromCharCodes((values as List<int>).where((c) => c != 0));
          } else {
            extractedKeywords = xpKeywords.printable;
          }
        } catch (_) {
          extractedKeywords = xpKeywords.printable;
        }
      } else if (imageDescription != null && imageDescription.printable.isNotEmpty) {
        extractedKeywords = imageDescription.printable;
      } else if (userComment != null && userComment.printable.isNotEmpty) {
        extractedKeywords = userComment.printable;
      }

      // GPS extractie uit BESTAND (Cruciaal voor thumbnails)
      double? lat;
      double? lon;
      final latitude = data['GPS GPSLatitude'];
      final latitudeRef = data['GPS GPSLatitudeRef'];
      final longitude = data['GPS GPSLongitude'];
      final longitudeRef = data['GPS GPSLongitudeRef'];

      if (latitude != null && latitudeRef != null && longitude != null && longitudeRef != null) {
        lat = _convertTagToDouble(latitude);
        if (latitudeRef.printable == 'S') lat = lat != null ? -lat : null;

        lon = _convertTagToDouble(longitude);
        if (longitudeRef.printable == 'W') lon = lon != null ? -lon : null;
        
        if (lat != null && lon != null) {
          // GPS gevonden
        }
      }

      String? locationName;
      final Set<String> locTags = {};
      if (lat != null && lon != null) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon).timeout(const Duration(seconds: 10));
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final city = p.locality ?? p.subLocality ?? p.administrativeArea;
            final country = p.country;
            
            if (city != null) {
              locationName = country != null ? '$city, $country' : city;
              locTags.add(city.toLowerCase());
            } else if (country != null) {
              locationName = country;
            }
            if (country != null) locTags.add(country.toLowerCase());
          }
        } catch (_) {}
      }

      DateTime? exifDate;
      final String? dateOriginal = data['EXIF DateTimeOriginal']?.printable;
      final String? dateDigitized = data['EXIF DateTimeDigitized']?.printable;
      final String? dateImage = data['Image DateTime']?.printable;
      
      List<DateTime> foundDates = [];
      void parseAndAdd(String? s) {
        if (s == null) return;
        try {
          final parts = s.split(' ');
          if (parts.length == 2) {
            final dateParts = parts[0].replaceAll(':', '-');
            final d = DateTime.tryParse('$dateParts ${parts[1]}');
            if (d != null) foundDates.add(d);
          }
        } catch (_) {}
      }

      parseAndAdd(dateOriginal);
      parseAndAdd(dateDigitized);
      parseAndAdd(dateImage);

      if (foundDates.isNotEmpty) {
        foundDates.sort();
        exifDate = foundDates.first;
      }

      final photoRecord = await (_db.select(_db.photos)..where((t) => t.id.equals(photoId))).getSingle();
      final Set<String> allTags = Set<String>.from(photoRecord.aiTags);
      allTags.addAll(locTags);

      await (_db.update(_db.photos)..where((t) => t.id.equals(photoId))).write(
        PhotosCompanion(
          cameraModel: camera != null ? Value(camera) : const Value.absent(),
          exposureTime: exposure != null ? Value(exposure) : const Value.absent(),
          fNumber: fNumber != null ? Value('f/$fNumber') : const Value.absent(),
          iso: iso != null ? Value(int.tryParse(iso)) : const Value.absent(),
          focalLength: focal != null ? Value('${focal}mm') : const Value.absent(),
          flash: flash != null ? Value(flash) : const Value.absent(),
          lensModel: lens != null ? Value(lens) : const Value.absent(),
          locationName: locationName != null ? Value(locationName) : const Value.absent(),
          dateTaken: exifDate != null ? Value(exifDate) : const Value.absent(),
          latitude: lat != null ? Value(lat) : const Value.absent(),
          longitude: lon != null ? Value(lon) : const Value.absent(),
          aiTags: Value(allTags.toList()),
          keywords: extractedKeywords != null ? Value(extractedKeywords) : const Value.absent(),
        ),
      );
    } catch (e) {
      debugPrint('Sync: Fout bij lokaal uitlezen EXIF voor foto $photoId: $e');
    }
  }

  double? _convertTagToDouble(IfdTag tag) {
    try {
      final values = tag.values.toList();
      if (values.length == 3) {
        final double degrees = _ratioToDouble(values[0]);
        final double minutes = _ratioToDouble(values[1]);
        final double seconds = _ratioToDouble(values[2]);
        return degrees + (minutes / 60.0) + (seconds / 3600.0);
      }
    } catch (_) {}
    return null;
  }

  double _ratioToDouble(dynamic ratio) {
    if (ratio is num) return ratio.toDouble();
    try {
      return ratio.numerator / ratio.denominator;
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> _flushMetadata(List<PhotosCompanion> buffer) async {
    await _db.batch((batch) {
      batch.insertAll(_db.photos, buffer, mode: InsertMode.insertOrIgnore);
    });
  }

  bool _isSupportedMedia(String name) {
    return _isImage(name) || _isVideo(name);
  }

  bool _isImage(String name) {
    final ext = p.extension(name).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'].contains(ext);
  }

  bool _isVideo(String name) {
    final ext = p.extension(name).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(ext);
  }

  Future<void> preDownloadHighRes() async {
    final photos = await _db.getAllPhotos();
    final localDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(localDir.path, 'photos'));
    if (!photosDir.existsSync()) photosDir.createSync();

    final toDownload = photos.where((p) => p.localHighResPath == null || !File(p.localHighResPath!).existsSync()).toList();
    
    for (var photo in toDownload) {
      final localPath = p.join(photosDir.path, photo.fileName);
      try {
        await _apiService.downloadFile(photo.kdrivePath, localPath);
        if (File(localPath).existsSync()) {
          await (_db.update(_db.photos)..where((t) => t.id.equals(photo.id)))
              .write(PhotosCompanion(localHighResPath: Value(localPath)));
          await updateMetadataFromFile(photo.id, localPath);
        }
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        await Future.delayed(const Duration(seconds: 10));
      }
    }
  }

  Future<void> _geocodeAndAddTags(String fileId, double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon).timeout(const Duration(seconds: 10));
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = p.locality ?? p.subLocality ?? p.administrativeArea;
        final country = p.country;
        
        String? locationName;
        final List<String> locTags = [];
        
        if (city != null) {
          locationName = country != null ? '$city, $country' : city;
          locTags.add(city.toLowerCase());
        } else if (country != null) {
          locationName = country;
        }
        if (country != null) locTags.add(country.toLowerCase());

        final existing = await _db.getPhotoByKdriveId(fileId);
        if (existing != null && locationName != null) {
          final Set<String> allTags = Set<String>.from(existing.aiTags);
          allTags.addAll(locTags);
          
          await (_db.update(_db.photos)..where((t) => t.id.equals(existing.id))).write(
            PhotosCompanion(
              locationName: Value(locationName),
              aiTags: Value(allTags.toList()),
            ),
          );
          debugPrint('Sync: Achtergrond geocoding voltooid voor $fileId: $locationName');
        }
      }
    } catch (e) {
      debugPrint('Sync: Achtergrond geocoding mislukt voor $fileId: $e');
    }
  }
}
