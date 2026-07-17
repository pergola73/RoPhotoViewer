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
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:kphoto/main.dart';
import 'package:kphoto/core/services/media_processor_service.dart';
import 'package:kphoto/core/services/ai_tagging_service.dart';

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
  bool _isThrottled = false; // VIP Modus voor grote fotos

  SyncEngine(this._apiService, this._db, {MediaProcessorService? mediaProcessor}) 
      : _mediaProcessor = mediaProcessor;

  void setThrottle(bool throttle) {
    _isThrottled = throttle;
    debugPrint('Sync: Turbo is nu ${_isThrottled ? "BEGRENSD (VIP modus)" : "MAXIMAAL"}');
  }

  KDriveApiService get apiService => _apiService;

  Future<void> sync(
    List<String> rootFolderIds, {
    Function(int)? onProgress,
    Function(int, int)? onIndexingProgress,
    bool isInitialSync = false,
  }) async {
    if (_isSyncing) return;
    
    debugPrint('Sync: Start poging met mappen: $rootFolderIds');
    
    if (rootFolderIds.isEmpty) {
      debugPrint('Sync: AFGEBROKEN - De mappenlijst is leeg.');
      return;
    }
    
    _isSyncing = true;
    _startForegroundService();

    final List<Map<String, dynamic>> pendingInitialSync = [];

    try {
      final Set<String> existingIds = await _db.getAllKdrivePaths();
      final localDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory(p.join(localDir.path, 'thumbnails'));
      if (!thumbDir.existsSync()) thumbDir.createSync(recursive: true);

      final List<String> folderQueue = List.from(rootFolderIds);
      final Set<String> visitedFolders = Set.from(rootFolderIds);
      int totalProcessed = 0;
      int totalNew = 0;

      while (folderQueue.isNotEmpty) {
        final currentFolderId = folderQueue.removeAt(0);

        try {
          await for (final batch in _apiService.getChildrenStream(currentFolderId)) {
            final processedResults = await compute(_processBatchInIsolate, batch);
            
            for (final result in processedResults) {
              final fileId = result['id'];
              if (result['isFolder']) {
                if (!visitedFolders.contains(fileId)) {
                  visitedFolders.add(fileId);
                  folderQueue.add(fileId);
                }
                continue;
              }
              if (existingIds.contains(fileId)) continue;
              
              pendingInitialSync.add(result);
              totalNew++;
            }

            // Verlaagd naar 50 voor snellere visuele feedback bij de start
            if (pendingInitialSync.length >= 50) {
              final batchToProcess = List<Map<String, dynamic>>.from(pendingInitialSync);
              pendingInitialSync.clear();
              unawaited(_processInitialMetadataBatch(batchToProcess, onProgress));
            }
          }
        } catch (e) {
          debugPrint('Sync error in folder $currentFolderId: $e');
        }
      }

      // De metadata en thumbnails gaan nu via de pipeline in _processInitialMetadataBatch
      // We hoeven hier alleen te wachten tot de namen-scan klaar is.
      debugPrint('Sync: Namen-scan voltooid. Pipeline verwerkt de rest...');

      if (isInitialSync) {
        debugPrint('Sync: Basis scan voltooid.');
      }

    } catch (e) {
      debugPrint('Global sync error: $e');
    } finally {
      _isSyncing = false;
      await _stopForegroundService();
    }
  }

  Future<void> _processInitialMetadataBatch(List<Map<String, dynamic>> batch, Function(int)? onProgress) async {
    final int concurrency = _isThrottled ? 5 : 100; // Drastisch verlagen als gebruiker kijkt
    List<PhotosCompanion> toInsert = [];

    for (int i = 0; i < batch.length; i += concurrency) {
      final chunk = batch.skip(i).take(concurrency);
      await Future.wait(chunk.map((item) async {
        try {
          final header = await _apiService.downloadHeader(item['id']);
          PhotoMetadata? metadata;
          if (header != null) {
            metadata = await compute(_extractExifFromBytes, header);
          }

          final finalDate = metadata?.date ?? DateTime.parse(item['dateTaken']);
          
          final companion = PhotosCompanion.insert(
            fileName: item['name'],
            kdrivePath: item['id'],
            dateTaken: finalDate,
            aiTags: const [],
            cameraModel: Value(metadata?.camera),
            latitude: Value(metadata?.lat),
            longitude: Value(metadata?.lon),
            mediaType: Value(item['mediaType']),
            keywords: const Value('header_processed'),
          );

          // Direct in de database zetten
          final id = await _db.into(_db.photos).insert(companion, mode: InsertMode.insertOrIgnore);
          
          // CRUCIAAL: Meteen de thumbnail downloaden voor deze specifieke foto!
          if (id > 0) {
            unawaited(_downloadSingleThumbnail(id, item['id']));
          }
        } catch (_) {}
      }));
    }
    
    // Update voortgang voor de UI
    onProgress?.call(batch.length);
  }

  Future<void> _downloadSingleThumbnail(int dbId, String kdrivePath) async {
    try {
      final localDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory(p.join(localDir.path, 'thumbnails'));
      final localThumbPath = p.join(thumbDir.path, 'thumb_$dbId.jpg');
      
      await _apiService.downloadThumbnail(kdrivePath, localThumbPath);
      
      if (File(localThumbPath).existsSync()) {
        await (_db.update(_db.photos)..where((t) => t.id.equals(dbId))).write(
          PhotosCompanion(localThumbnailPath: Value(localThumbPath))
        );
      }
    } catch (e) {
      debugPrint('Sync: Thumbnail download mislukt voor $dbId');
    }
  }

  Future<void> _continueBackgroundThumbnails(Function(int)? onProgress) async {
    unawaited(() async {
      await _downloadMissingThumbnails(onProgress);
      // AI scan volgt hierna automatisch
    }());
  }

  Future<void> _fetchHeadersInParallel(int count, Function(int)? onProgress, {int? limit}) async {
    var query = _db.select(_db.photos)..where((t) => t.cameraModel.isNull());
    if (limit != null) {
      query.orderBy([(t) => OrderingTerm(expression: t.dateTaken, mode: OrderingMode.desc)]);
      query.limit(limit);
    }
    
    final pending = await query.get();
    if (pending.isEmpty) return;

    int done = 0;
    const int concurrency = 100; // TURBO 8KB

    for (int i = 0; i < pending.length; i += concurrency) {
      final chunk = pending.skip(i).take(concurrency).toList();
      await Future.wait(chunk.map((photo) async {
        try {
          final header = await _apiService.downloadHeader(photo.kdrivePath);
          if (header != null) {
            final metadata = await compute(_extractExifFromBytes, header);
            if (metadata != null) {
              await (_db.update(_db.photos)..where((t) => t.id.equals(photo.id))).write(
                PhotosCompanion(
                  dateTaken: metadata.date != null ? Value(metadata.date!) : const Value.absent(),
                  cameraModel: Value(metadata.camera),
                  latitude: Value(metadata.lat),
                  longitude: Value(metadata.lon),
                  keywords: const Value('header_processed'),
                ),
              );
            }
          }
        } catch (_) {}
      }));
      done += chunk.length;
      if (onProgress != null) onProgress(done);
    }
  }

  static Future<PhotoMetadata?> _extractExifFromBytes(List<int> bytes) async {
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

  Future<void> _startForegroundService() async {
    if (!Platform.isAndroid) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(channelId: 'sync_service', channelName: 'K-Photo Sync', channelDescription: 'Sync...', channelImportance: NotificationChannelImportance.LOW, priority: NotificationPriority.LOW),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: true, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(eventAction: ForegroundTaskEventAction.repeat(5000), allowWakeLock: true, allowWifiLock: true),
    );
    await FlutterForegroundTask.startService(notificationTitle: 'K-Photo Sync', notificationText: 'Bezig...', callback: startCallback);
  }

  Future<void> _stopForegroundService() async {
    if (Platform.isAndroid) await FlutterForegroundTask.stopService();
  }

  Future<void> _downloadMissingThumbnails(Function(int)? onProgress, {int? limit}) async {
    if (_isDownloadingThumbnails) return;
    _isDownloadingThumbnails = true;

    try {
      final localDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory(p.join(localDir.path, 'thumbnails'));
      var query = _db.select(_db.photos)
        ..where((t) => t.localThumbnailPath.isNull())
        ..orderBy([(t) => OrderingTerm(expression: t.dateTaken, mode: OrderingMode.desc)]);
      
      if (limit != null) query.limit(limit);
      
      final pendingPhotos = await query.get();

      if (pendingPhotos.isEmpty) return;

      int downloaded = 0;
      final int concurrency = _isThrottled ? 2 : 40; // Geef grote fotos de ruimte

      for (int i = 0; i < pendingPhotos.length; i += concurrency) {
        final chunk = pendingPhotos.skip(i).take(concurrency).toList();
        await Future.wait(chunk.map((photo) async {
          final localThumbPath = p.join(thumbDir.path, 'thumb_${photo.id}.jpg');
          try {
            await _apiService.downloadThumbnail(photo.kdrivePath, localThumbPath).timeout(const Duration(seconds: 15));
            if (File(localThumbPath).existsSync() && File(localThumbPath).lengthSync() > 0) {
              await (_db.update(_db.photos)..where((t) => t.id.equals(photo.id))).write(PhotosCompanion(localThumbnailPath: Value(localThumbPath)));
            }
          } catch (_) {}
        }));
        downloaded += chunk.length;
        if (onProgress != null && downloaded % 12 == 0) onProgress(downloaded);
      }
    } finally {
      _isDownloadingThumbnails = false;
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
      return _extractExifFromBytes(bytes);
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

      results.add({
        'isFolder': false,
        'id': fileId,
        'name': name,
        'dateTaken': _extractDateStatic(item).toIso8601String(),
        'mediaType': _isVideoStatic(name) ? 'video' : 'image',
        'lat': _toDoubleStatic(item['exif']?['gps']?['latitude']),
        'lon': _toDoubleStatic(item['exif']?['gps']?['longitude']),
        'locationName': item['exif']?['location']?['name']?.toString(),
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

  Future<void> _flushMetadata(List<PhotosCompanion> buffer) async {
    await _db.batch((batch) => batch.insertAll(_db.photos, buffer, mode: InsertMode.insertOrIgnore));
  }
}
