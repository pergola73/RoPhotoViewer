import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ro_photo_viewer/core/database/app_database.dart';
import 'package:ro_photo_viewer/core/network/kdrive_api_service.dart';

import 'package:ro_photo_viewer/core/services/ai_tagging_service.dart';

class SyncEngine {
  final KDriveApiService _apiService;
  final AppDatabase _db;
  bool _isSyncing = false;

  SyncEngine(this._apiService, this._db);

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
              if (item['exif'] != null) {
                debugPrint('Sync: EXIF data gevonden voor ${item['name']}: ${item['exif']}');
              }
              final name = item['name']?.toString() ?? '';
              final type = item['type']?.toString(); 
              final mimeType = item['mime_type']?.toString();
              final fileId = (item['id'] ?? item['file_id'] ?? item['node_id'])?.toString();

              if (fileId == null) {
                debugPrint('Sync: Overslaan item zonder ID: $name');
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

              // Alleen afbeeldingen verwerken
              if (!_isImage(name)) {
                // Minder herrie in de logs voor bekende types
                if (type != 'file' || !['.pdf', '.docx', '.zip'].contains(p.extension(name).toLowerCase())) {
                  debugPrint('Sync: Overslaan (geen afbeelding): $name');
                }
                continue;
              }

              totalProcessed++;
              debugPrint('Sync: Gevonden foto ($totalProcessed): $name (ID: $fileId)');
              
              final existing = await _db.getPhotoByKdriveId(fileId);
              if (existing != null) {
                if (existing.localThumbnailPath == null || !File(existing.localThumbnailPath!).existsSync()) {
                  photosToDownloadInBatch.add(existing);
                }
                continue;
              }

              // Metadata extraheren
              final DateTime dateTaken = _extractDate(item);
              
              // Verbeterde locatie extractie
              String? locationName;
              double? lat;
              double? lon;

              final dynamic exif = item['exif'];
              if (exif != null) {
                locationName = exif['location']?['name']?.toString();
                
                // Sommige API versies hebben GPS direct in EXIF, anderen in een sub-object
                final dynamic gps = exif['gps'] ?? exif['location']?['gps'];
                if (gps != null) {
                  lat = _toDouble(gps['latitude'] ?? gps['lat']);
                  lon = _toDouble(gps['longitude'] ?? gps['lon']);
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
          // We gaan door naar de volgende map in de queue
        }
      }

      debugPrint('Sync: Klaar. $totalNew nieuwe foto\'s gevonden.');

      // Start AI tagging voor nieuwe foto's
      final aiService = AITaggingService(_db);
      aiService.processPendingPhotos();

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

    final dynamic rawTime = exifDate ?? lastMod ?? createdAt;

    if (rawTime is num) {
      int ts = rawTime.toInt();
      if (ts > 32503680000) ts = ts ~/ 1000;
      return DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    } else if (rawTime is String) {
      return DateTime.tryParse(rawTime) ?? DateTime.now();
    }
    return DateTime.now();
  }

  double? _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  Future<void> _downloadThumbnails(List<Photo> photos, Directory thumbDir) async {
    const int concurrency = 2; // Iets hoger nu we gerichter werken
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
            await (_db.update(_db.photos)
              ..where((t) => t.id.equals(photo.id)))
                .write(PhotosCompanion(localThumbnailPath: Value(localThumbPath)));
          } else {
            if (file.existsSync()) file.deleteSync();
          }
        } catch (e) {
          debugPrint('Sync: Thumbnail mislukt voor ${photo.fileName}: $e');
        }
      }));
      // Wacht even tussen paren thumbnails om de rate limit te sparen (ongeveer 2 per seconde = 120 per minuut)
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  Future<void> _flushMetadata(List<PhotosCompanion> buffer) async {
    debugPrint('Sync: Opslaan van ${buffer.length} nieuwe foto-metadata records...');
    await _db.batch((batch) {
      batch.insertAll(_db.photos, buffer, mode: InsertMode.insertOrIgnore);
    });
    debugPrint('Sync: Metadata opgeslagen.');
  }

  bool _isImage(String name) {
    final ext = p.extension(name).toLowerCase();
    final isImg = ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'].contains(ext);
    if (!isImg && name.toLowerCase().contains('.')) {
      debugPrint('Sync: Extensie $ext niet herkend als afbeelding voor $name');
    }
    return isImg;
  }
}