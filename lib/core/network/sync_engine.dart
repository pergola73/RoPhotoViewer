import 'dart:io';
import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ro_photo_viewer/core/database/app_database.dart';
import 'package:ro_photo_viewer/core/network/kdrive_api_service.dart';
import 'package:exif/exif.dart';
import 'package:geocoding/geocoding.dart';

import 'package:ro_photo_viewer/core/services/ai_tagging_service.dart';

class SyncEngine {
  final KDriveApiService _apiService;
  final AppDatabase _db;
  bool _isSyncing = false;

  SyncEngine(this._apiService, this._db);

  KDriveApiService get apiService => _apiService;

  Future<void> sync(String rootFolderId, {Function(int)? onProgress}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    debugPrint('Sync: Starten BFS sync vanaf map $rootFolderId...');

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
        debugPrint('Sync: Verwerken map $currentFolderId (Nog ${folderQueue.length} mappen in wachtrij)');

        try {
          await for (final batch in _apiService.getChildrenStream(currentFolderId)) {
            List<PhotosCompanion> metadataBuffer = [];
            List<Photo> photosToDownloadInBatch = [];

            for (final item in batch) {
              final name = item['name']?.toString() ?? '';
              final type = item['type']?.toString(); 
              final mimeType = item['mime_type']?.toString();
              final fileId = (item['id'] ?? item['file_id'] ?? item['node_id'])?.toString();

              if (fileId == null) {
                continue;
              }

              final bool isFolder = type == 'dir' || type == 'folder' || mimeType == 'application/x-directory' || type == 'node_dir';

              if (isFolder) {
                if (!visitedFolders.contains(fileId)) {
                  // Voorkom loops en negeer irrelevante systeem-mappen
                  if (fileId == currentFolderId) continue;

                  debugPrint('Sync: Nieuwe map ontdekt: $name (ID: $fileId)');
                  visitedFolders.add(fileId);
                  folderQueue.add(fileId);
                }
                continue;
              }

              final existing = await _db.getPhotoByKdriveId(fileId);
              if (existing != null) {
                // FORCEER UPDATE VOOR BESTAANDE FOTO'S:
                if (existing.cameraModel == null || existing.lensModel == null) {
                  final localFile = existing.localHighResPath ?? existing.localThumbnailPath;
                  if (localFile != null && File(localFile).existsSync()) {
                    // Start meteen op de achtergrond zonder de sync-loop te blokkeren
                    unawaited(_updateMetadataFromFile(existing.id, localFile));
                  }
                }

                // Sla de onnodige kDrive API EXIF calls over
                if (existing.localThumbnailPath == null || !File(existing.localThumbnailPath!).existsSync()) {
                  photosToDownloadInBatch.add(existing);
                }
                continue;
              }

              // Alleen media verwerken
              if (!_isSupportedMedia(name)) {
                continue;
              }

              final bool isVideo = _isVideo(name);
              final mediaType = isVideo ? 'video' : 'image';

              totalProcessed++;
              
              // Metadata extraheren
              final DateTime dateTaken = _extractDate(item);
              
              // Verbeterde locatie extractie
              String? locationName;
              double? lat;
              double? lon;
              int? duration;
              String? cameraModel;
              String? exposureTime;
              String? fNumber;
              int? iso;
              String? focalLength;

              final dynamic exif = item['exif'];
              if (exif != null) {
                locationName = exif['location']?['name']?.toString();
                
                final dynamic gps = exif['gps'] ?? exif['location']?['gps'];
                if (gps != null) {
                  lat = _toDouble(gps['latitude'] ?? gps['lat']);
                  lon = _toDouble(gps['longitude'] ?? gps['lon']);
                }
                
                if (isVideo) {
                  duration = (exif['duration'] as num?)?.toInt();
                } else {
                  cameraModel = exif['model']?.toString() ?? exif['make']?.toString();
                  exposureTime = exif['exposure_time']?.toString();
                  fNumber = exif['f_number'] != null ? 'f/${exif['f_number']}' : null;
                  iso = (exif['iso'] as num?)?.toInt();
                  focalLength = exif['focal_length'] != null ? '${exif['focal_length']}mm' : null;
                }
              }

              metadataBuffer.add(PhotosCompanion.insert(
                fileName: name,
                kdrivePath: fileId,
                dateTaken: dateTaken,
                aiTags: const [],
                locationName: Value(locationName),
                latitude: Value(lat),
                longitude: Value(lon),
                mediaType: Value(mediaType),
                duration: Value(duration),
                cameraModel: Value(cameraModel),
                exposureTime: Value(exposureTime),
                fNumber: Value(fNumber),
                iso: Value(iso),
                focalLength: Value(focalLength),
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
          debugPrint('Sync: Map $currentFolderId mislukt, doorgaan met de rest... Fout: $e');
        }
      }

      debugPrint('Sync: Klaar. $totalNew nieuwe media bestanden gevonden.');

      // Start AI tagging voor nieuwe foto's
      final aiService = AITaggingService(_db);
      aiService.processPendingPhotos();

      // Start achtergrond download van high-res foto's (nieuwste eerst)
      preDownloadHighRes();

    } catch (e, stack) {
      debugPrint('Sync: Fout — $e\n$stack');
    } finally {
      _isSyncing = false;
      debugPrint('Sync: Volledig afgerond.');
    }
  }

  DateTime _extractDate(Map<String, dynamic> item) {
    final dynamic exif = item['exif'];
    final dynamic exifDate = exif?['date_taken'] ?? exif?['date_time_original'] ?? exif?['date_time'];
    final dynamic lastMod = item['last_modified'] ?? item['mtime'];
    final dynamic createdAt = item['created_at'];

    List<DateTime> dates = [];

    void addDate(dynamic raw) {
      if (raw == null) return;
      DateTime? parsed;
      if (raw is num) {
        int ts = raw.toInt();
        if (ts > 32503680000) ts = ts ~/ 1000;
        parsed = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      } else if (raw is String) {
        parsed = DateTime.tryParse(raw);
      }
      if (parsed != null) dates.add(parsed);
    }

    addDate(exifDate);
    addDate(lastMod);
    addDate(createdAt);

    if (dates.isEmpty) return DateTime.now();

    dates.sort();
    return dates.first;
  }

  double? _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  Future<void> _downloadThumbnails(List<Photo> photos, Directory thumbDir) async {
    const int concurrency = 2;
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
            // Update eerst de thumbnail pad
            await (_db.update(_db.photos)
              ..where((t) => t.id.equals(photo.id)))
                .write(PhotosCompanion(localThumbnailPath: Value(localThumbPath)));
            
            // DIRECT EXIF UITLEZEN op de achtergrond
            // We wachten hier niet op (unawaited), zodat de volgende download direct kan starten
            unawaited(_updateMetadataFromFile(photo.id, localThumbPath));
          } else {
            if (file.existsSync()) file.deleteSync();
          }
        } catch (e) {
          debugPrint('Sync: Thumbnail/EXIF mislukt voor ${photo.fileName}: $e');
        }
      }));
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  Future<void> _updateMetadataFromFile(int photoId, String filePath) async {
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
      }

      // Adres bepalen op basis van GPS
      String? locationName;
      if (lat != null && lon != null) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final city = p.locality ?? p.subLocality ?? p.administrativeArea;
            final country = p.country;
            
            if (city != null) {
              if (country != null && country.toLowerCase() != 'netherlands' && country.toLowerCase() != 'nederland') {
                locationName = '$city ($country)';
              } else {
                locationName = city;
              }
            }
          }
        } catch (e) {
          debugPrint('Sync: Geocoding mislukt voor foto $photoId: $e');
        }
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

      await (_db.update(_db.photos)..where((t) => t.id.equals(photoId))).write(
        PhotosCompanion(
          cameraModel: Value(camera),
          exposureTime: Value(exposure),
          fNumber: Value(fNumber != null ? 'f/$fNumber' : null),
          iso: Value(iso != null ? int.tryParse(iso) : null),
          focalLength: Value(focal != null ? '${focal}mm' : null),
          flash: Value(flash),
          lensModel: Value(lens),
          dateTaken: exifDate != null ? Value(exifDate) : const Value.absent(),
          latitude: lat != null ? Value(lat) : const Value.absent(),
          longitude: lon != null ? Value(lon) : const Value.absent(),
          locationName: Value(locationName),
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
          await _updateMetadataFromFile(photo.id, localPath);
        }
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        await Future.delayed(const Duration(seconds: 10));
      }
    }
  }
}
