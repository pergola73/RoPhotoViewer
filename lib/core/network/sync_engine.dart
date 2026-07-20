import 'dart:io';
import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:kphoto/core/database/app_database.dart';
import 'package:kphoto/core/network/kdrive_api_service.dart';
import 'package:exif/exif.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:kphoto/main.dart';
import 'package:kphoto/core/services/media_processor_service.dart';
import 'package:kphoto/core/services/ai_tagging_service.dart';
import 'package:kphoto/core/models/sync_phase.dart';

class PhotoMetadata {
  final String? camera;
  final String? exposure;
  final String? fNumber;
  final int? iso;
  final String? focal;
  final String? flash;
  final String? lens;
  final String? keywords;
  final double? lat;
  final double? lon;
  final DateTime? date;

  PhotoMetadata({this.camera, this.exposure, this.fNumber, this.iso, this.focal, this.flash, this.lens, this.keywords, this.lat, this.lon, this.date});
}

class SyncEngine {
  final KDriveApiService _apiService;
  final AppDatabase _db;
  final MediaProcessorService? _mediaProcessor;
  bool _isSyncing = false;
  bool _isDownloadingThumbnails = false;
  bool _isThrottled = false; 

  SyncEngine(this._apiService, this._db, {MediaProcessorService? mediaProcessor}) 
      : _mediaProcessor = mediaProcessor;

  void setThrottle(bool throttle) {
    if (_isThrottled == throttle) return;
    _isThrottled = throttle;
    debugPrint('Sync: Turbo modus: ${_isThrottled ? "VIP (2 streams)" : "MAX (15 streams)"}');
  }

  KDriveApiService get apiService => _apiService;

  Future<void> sync(
    List<String> rootFolderIds, {
    Function(int, SyncPhase)? onProgress,
    Function(int, int)? onIndexingProgress,
    bool isInitialSync = false,
  }) async {
    if (_isSyncing) {
      debugPrint('Sync: Er loopt al een synchronisatie.');
      return;
    }
    
    debugPrint('Sync: Start poging met mappen: $rootFolderIds');
    
    if (rootFolderIds.isEmpty) {
      debugPrint('Sync: AFGEBROKEN - De mappenlijst is leeg.');
      return;
    }
    
    _isSyncing = true;
    _startForegroundService();

    try {
      final Set<String> existingIds = await _db.getAllKdrivePaths();
      final localDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory(p.join(localDir.path, 'thumbnails'));
      if (!thumbDir.existsSync()) thumbDir.createSync(recursive: true);

      final List<String> folderQueue = List.from(rootFolderIds);
      final Set<String> visitedFolders = Set.from(rootFolderIds);
      int totalScannedCount = 0;

      // Start de thumbnail downloader alvast in de achtergrond
      _startBackgroundThumbnailDownloader(onProgress, onIndexingProgress);

      while (folderQueue.isNotEmpty) {
        final currentFolderId = folderQueue.removeAt(0);
        
        final lastSyncDate = await _db.getLastSyncForFolder(currentFolderId);
        final folderInfo = await _apiService.getFileInfo(currentFolderId);
        
        if (folderInfo != null && lastSyncDate != null) {
          final serverModified = DateTime.tryParse(folderInfo['last_modified']?.toString() ?? '');
          // Als de map korter dan 5 min geleden is aangepast, scannen we hem sowieso (marge voor tijdverschil)
          if (serverModified != null && serverModified.isBefore(lastSyncDate.subtract(const Duration(minutes: 5)))) {
            debugPrint('Sync: Map ${folderInfo['name']} is ongewijzigd, overslaan.');
            continue;
          }
        }

        String folderName = folderInfo?['name']?.toString() ?? 'Onbekend';
        debugPrint('Sync: Scannen map $folderName ($currentFolderId)');

        try {
          await for (final batch in _apiService.getChildrenStream(currentFolderId)) {
            final processedResults = await compute(_processBatchInIsolate, batch);
            
            final List<Map<String, dynamic>> newItemsInBatch = [];

            for (final result in processedResults) {
              final fileId = result['id'];
              if (result['isFolder']) {
                if (!visitedFolders.contains(fileId)) {
                  visitedFolders.add(fileId);
                  folderQueue.add(fileId);
                }
                continue;
              }
              
              totalScannedCount++;
              onProgress?.call(totalScannedCount, SyncPhase.scanning);

              if (existingIds.contains(fileId)) {
                continue;
              }
              
              result['kdriveFolderName'] = folderName;
              result['kdriveFolderId'] = currentFolderId;
              
              newItemsInBatch.add(result);
              existingIds.add(fileId);
            }

            if (newItemsInBatch.isNotEmpty) {
              await _processNewItemsBatch(newItemsInBatch, onProgress);
              // Trigger downloader na elke batch nieuwe items
              _startBackgroundThumbnailDownloader(onProgress, onIndexingProgress);
            }
          }

          await _db.updateLastSyncForFolder(currentFolderId);

        } catch (e) {
          debugPrint('Sync error in folder $currentFolderId: $e');
        }
      }

      debugPrint('Sync: Namen-scan voltooid. Totaal gescand: $totalScannedCount');
      
      // Finale pass om alles af te ronden
      await _downloadMissingThumbnails(onProgress, onIndexingProgress);

    } catch (e) {
      debugPrint('Global sync error: $e');
    } finally {
      _isSyncing = false;
      await _stopForegroundService();
      debugPrint('Sync: Volledig klaar.');
    }
  }

  void _startBackgroundThumbnailDownloader(Function(int, SyncPhase)? onProgress, [Function(int, int)? onIndexingProgress]) {
    if (_isDownloadingThumbnails) return;
    unawaited(_downloadMissingThumbnails(onProgress, onIndexingProgress));
  }

  Future<void> _processNewItemsBatch(List<Map<String, dynamic>> batch, Function(int, SyncPhase)? onProgress) async {
    final int concurrency = _isThrottled ? 2 : 10; 
    
    for (int i = 0; i < batch.length; i += concurrency) {
      final chunk = batch.skip(i).take(concurrency).toList();
      
      await Future.wait(chunk.map((item) async {
        try {
          DateTime finalDate = DateTime.parse(item['dateTaken']);
          PhotoMetadata? metadata;

          // Alleen header downloaden als kDrive geen EXIF data meegaf in de list response
          if (item['hasExif'] != true) {
             final header = await _apiService.downloadHeader(item['id']).timeout(const Duration(seconds: 5), onTimeout: () => null);
             if (header != null) {
               metadata = await compute(SyncEngine.extractExifFromBytesStatic, header);
               if (metadata?.date != null) finalDate = metadata!.date!;
             }
          }

          final companion = PhotosCompanion.insert(
            fileName: item['name'],
            kdrivePath: item['id'],
            dateTaken: finalDate,
            aiTags: const [],
            cameraModel: Value(metadata?.camera),
            latitude: Value(metadata?.lat ?? item['lat']),
            longitude: Value(metadata?.lon ?? item['lon']),
            mediaType: Value(item['mediaType']),
            locationName: Value(item['locationName']),
            kdriveFolderName: Value(item['kdriveFolderName']),
            kdriveFolderId: Value(item['kdriveFolderId']),
          );

          await _db.into(_db.photos).insert(companion, mode: InsertMode.insertOrIgnore);
          
        } catch (e) {
          debugPrint('Sync: Error processing item ${item['name']}: $e');
        }
      }));
      
      if (onProgress != null) {
        final currentTotal = await _db.getTotalPhotoCount();
        onProgress(currentTotal, SyncPhase.downloading);
      }
    }
  }

  Future<void> _downloadMissingThumbnails(Function(int, SyncPhase)? onProgress, [Function(int, int)? onIndexingProgress]) async {
    if (_isDownloadingThumbnails) return;
    _isDownloadingThumbnails = true;

    try {
      int batchProcessCount = 0;
      while (true) {
        final pendingPhotos = await (_db.select(_db.photos)
          ..where((t) => t.localThumbnailPath.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.dateTaken, mode: OrderingMode.desc)])
          ..limit(50)).get();
        
        if (pendingPhotos.isEmpty) break;

        final int concurrency = _isThrottled ? 2 : 15; 

        for (int i = 0; i < pendingPhotos.length; i += concurrency) {
          final chunk = pendingPhotos.skip(i).take(concurrency).toList();
          
          await Future.wait(chunk.map((photo) async {
            try {
              final localDir = await getApplicationDocumentsDirectory();
              final thumbDir = Directory(p.join(localDir.path, 'thumbnails'));
              final localThumbPath = p.join(thumbDir.path, 'thumb_${photo.id}.jpg');
              
              if (File(localThumbPath).existsSync() && File(localThumbPath).lengthSync() > 0) {
                 await (_db.update(_db.photos)..where((t) => t.id.equals(photo.id))).write(
                    PhotosCompanion(localThumbnailPath: Value(localThumbPath))
                 );
                 return;
              }

              await _apiService.downloadThumbnail(photo.kdrivePath, localThumbPath)
                  .timeout(const Duration(seconds: 15));
              
              if (File(localThumbPath).existsSync() && File(localThumbPath).lengthSync() > 0) {
                await (_db.update(_db.photos)..where((t) => t.id.equals(photo.id))).write(
                  PhotosCompanion(localThumbnailPath: Value(localThumbPath))
                );
              }
            } catch (e) {
              debugPrint('Sync: Thumbnail download mislukt voor ${photo.id}: $e');
            }
          }));
          
          if (onProgress != null) {
            final currentTotal = await _db.getTotalPhotoCount();
            onProgress(currentTotal, SyncPhase.downloading);
          }
        }
        
        // Elke 100 thumbnails doen we een snelle AI-pass om resultaten in de zoekfunctie te krijgen
        batchProcessCount += pendingPhotos.length;
        if (batchProcessCount >= 100) {
           await _runAiAnalysis(onIndexingProgress);
           batchProcessCount = 0;
        }
      }
      
      // Finale AI Analyse
      await _runAiAnalysis(onIndexingProgress);

    } finally {
      _isDownloadingThumbnails = false;
    }
  }

  Future<void> _runAiAnalysis(Function(int, int)? onProgress) async {
    final aiService = AITaggingService(_db);
    try {
      // processPendingPhotos kijkt zelf welke foto's een thumbnail hebben maar nog geen AI tags
      await aiService.processPendingPhotos(onProgress: onProgress);
    } catch (e) {
      debugPrint('Sync: AI Analyse fout: $e');
    }
    
    if (_mediaProcessor != null) {
       final photos = await _db.getPhotosPaged(200, 0); // Doe alleen de meest recente voor vector search tijdens sync
       final paths = photos
          .where((p) => p.localThumbnailPath != null && File(p.localThumbnailPath!).existsSync())
          .map((p) => p.localThumbnailPath!)
          .toList();
       
       if (paths.isNotEmpty) {
         await _mediaProcessor!.processNewFiles(paths, onProgress: onProgress);
       }
    }
  }

  Future<void> updateMetadataFromFile(int photoId, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;
      final metadata = await compute(_extractExifInIsolate, filePath);
      if (metadata == null) return;

      await (_db.update(_db.photos)..where((t) => t.id.equals(photoId))).write(
        PhotosCompanion(
          cameraModel: Value(metadata.camera),
          dateTaken: metadata.date != null ? Value(metadata.date!) : const Value.absent(),
          latitude: Value(metadata.lat),
          longitude: Value(metadata.lon),
        ),
      );
    } catch (_) {}
  }

  static Future<PhotoMetadata?> _extractExifInIsolate(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      return SyncEngine.extractExifFromBytesStatic(bytes);
    } catch (_) { return null; }
  }

  static Future<PhotoMetadata?> extractExifFromBytesStatic(List<int> bytes) async {
    try {
      final data = await readExifFromBytes(bytes);
      if (data.isEmpty) return null;

      final String? make = data['Image Make']?.printable;
      final String? model = data['Image Model']?.printable;
      final String? camera = (make != null && model != null) 
          ? (model.contains(make) ? model : '$make $model') 
          : (model ?? make);

      double? lat;
      double? lon;
      final latitude = data['GPS GPSLatitude'];
      final latitudeRef = data['GPS GPSLatitudeRef'];
      final longitude = data['GPS GPSLongitude'];
      final longitudeRef = data['GPS GPSLongitudeRef'];

      if (latitude != null && latitudeRef != null && longitude != null && longitudeRef != null) {
        lat = _convertTagToDoubleStatic(latitude);
        if (latitudeRef.printable == 'S') lat = lat != null ? -lat : null;
        lon = _convertTagToDoubleStatic(longitude);
        if (longitudeRef.printable == 'W') lon = lon != null ? -lon : null;
      }

      DateTime? exifDate;
      final String? dateOriginal = data['EXIF DateTimeOriginal']?.printable;
      if (dateOriginal != null) {
        final parts = dateOriginal.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].replaceAll(':', '-');
          exifDate = DateTime.tryParse('$dateParts ${parts[1]}');
        }
      }

      return PhotoMetadata(camera: camera, lat: lat, lon: lon, date: exifDate);
    } catch (_) { return null; }
  }

  static List<Map<String, dynamic>> _processBatchInIsolate(List<dynamic> batch) {
    final List<Map<String, dynamic>> results = [];
    for (final item in batch) {
      final name = item['name']?.toString() ?? 'onbekend';
      final fileId = (item['id'] ?? item['file_id'] ?? item['node_id'] ?? item['node']?['id'])?.toString();
      if (fileId == null) continue;

      final type = item['type']?.toString(); 
      final mimeType = item['mime_type']?.toString();
      final bool isFolder = type == 'dir' || type == 'folder' || mimeType == 'application/x-directory' || type == 'node_dir';
      
      if (isFolder) {
        results.add({'isFolder': true, 'id': fileId});
        continue;
      }

      if (!_isImageStatic(name) && !_isVideoStatic(name)) continue;

      final exif = item['exif'];
      
      results.add({
        'isFolder': false,
        'id': fileId,
        'name': name,
        'dateTaken': _extractDateStatic(item).toIso8601String(),
        'mediaType': _isVideoStatic(name) ? 'video' : 'image',
        'lat': _toDoubleStatic(exif?['gps']?['latitude']),
        'lon': _toDoubleStatic(exif?['gps']?['longitude']),
        'locationName': exif?['location']?['name']?.toString(),
        'hasExif': exif != null,
        'tags': [],
      });
    }
    return results;
  }

  static DateTime _extractDateStatic(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? '';
    final RegExp dateRegex = RegExp(r'(\d{4})[-_]?(\d{2})[-_]?(\d{2})');
    final match = dateRegex.firstMatch(name);
    if (match != null) {
      try {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        if (year > 1990 && year < 2100 && month <= 12 && day <= 31) return DateTime(year, month, day);
      } catch (_) {}
    }
    final dynamic exif = item['exif'];
    final dynamic kDate = exif?['date_taken'] ?? exif?['date_time_original'];
    if (kDate != null) return _parseAnyDateStatic(kDate) ?? DateTime.now();
    return _parseAnyDateStatic(item['last_modified']) ?? DateTime.now();
  }

  static DateTime? _parseAnyDateStatic(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt() * 1000);
    return DateTime.tryParse(raw.toString());
  }

  static double? _toDoubleStatic(dynamic val) => (val is num) ? val.toDouble() : double.tryParse(val.toString());
  static double? _convertTagToDoubleStatic(IfdTag tag) {
    try {
      final values = tag.values.toList();
      if (values.length == 3) return _ratioToDoubleStatic(values[0]) + (_ratioToDoubleStatic(values[1]) / 60.0) + (_ratioToDoubleStatic(values[2]) / 3600.0);
    } catch (_) {}
    return null;
  }
  static double _ratioToDoubleStatic(dynamic ratio) {
    if (ratio is num) return ratio.toDouble();
    try { return ratio.numerator / ratio.denominator; } catch (_) { return 0.0; }
  }
  static bool _isImageStatic(String n) => ['.jpg', '.jpeg', '.png', '.webp', '.heic'].contains(p.extension(n).toLowerCase());
  static bool _isVideoStatic(String n) => ['.mp4', '.mov', '.avi'].contains(p.extension(n).toLowerCase());

  Future<void> _startForegroundService() async {
    if (!Platform.isAndroid) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sync_service', 
        channelName: 'K-Photo Sync', 
        channelDescription: 'Synchroniseren van fotos...', 
        channelImportance: NotificationChannelImportance.LOW, 
        priority: NotificationPriority.LOW
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: true, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), 
        allowWakeLock: true, 
        allowWifiLock: true
      ),
    );
    await FlutterForegroundTask.startService(notificationTitle: 'K-Photo Sync', notificationText: 'Bezig met synchroniseren...', callback: startCallback);
  }

  Future<void> _stopForegroundService() async {
    if (Platform.isAndroid) await FlutterForegroundTask.stopService();
  }
}
