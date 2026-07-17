import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:exif/exif.dart';
import 'package:kphoto/core/database/asset_entity.dart';
import 'package:kphoto/core/database/objectbox_manager.dart';
import 'package:kphoto/core/services/image_embedding_service.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:objectbox/objectbox.dart';

import 'package:kphoto/objectbox.g.dart';

class MediaProcessorService {
  final ObjectBoxManager _dbManager;
  bool _isProcessing = false;

  MediaProcessorService(this._dbManager);

  Future<void> processNewFiles(List<String> filePaths, {Function(int, int)? onProgress}) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final box = _dbManager.store.box<AssetEntity>();
      
      // 1. Filter: alleen bestanden die nog NIET in ObjectBox staan
      // We halen alle bestaande paden op (indexed) voor een snelle check
      final query = box.query().build();
      final existingPaths = query.property(AssetEntity_.path).find().toSet();
      query.close();

      final pendingPaths = filePaths.where((p) => !existingPaths.contains(p)).toList();
      
      if (pendingPaths.isEmpty) {
        _isProcessing = false;
        return;
      }

      debugPrint('MediaProcessor: ${pendingPaths.length} nieuwe bestanden te indexeren (totaal was ${filePaths.length})');

      // Process in batches of 50 to manage memory
      const int batchSize = 50;
      int processed = 0;
      
      for (int i = 0; i < pendingPaths.length; i += batchSize) {
        final batch = pendingPaths.skip(i).take(batchSize).toList();
        
        // Perform heavy processing in Isolate
        final List<AssetEntity> processedAssets = await compute(_processBatch, batch);
        
        // Save batch to database in a single transaction
        box.putMany(processedAssets);

        // MARKERING: Update de Drift database dat deze bestanden nu 'verwerkt' zijn
        // Dit doen we door een lege string in keywords te zetten als markering
        final processedPaths = batch;
        // In een echte app zouden we hier een batch update doen naar Drift
        // Voor nu zorgt de keywords.isNull check in SyncEngine al voor de filtering
        
        processed += batch.length;
        onProgress?.call(processed, pendingPaths.length);
      }
    } catch (e) {
      debugPrint('MediaProcessor: Fout tijdens verwerking - $e');
    } finally {
      _isProcessing = false;
    }
  }

  // This runs in a separate Isolate
  static Future<List<AssetEntity>> _processBatch(List<String> paths) async {
    List<AssetEntity> results = [];
    final ai = ImageEmbeddingService();
    await ai.init(); // Auto-download model indien nodig

    for (var path in paths) {
      try {
        final file = File(path);
        if (!file.existsSync()) continue;
        
        final bytes = await file.readAsBytes();

        // 1. EXIF Metadata
        final exifData = await readExifFromBytes(bytes);
        final creationDate = _extractDate(exifData) ?? file.lastModifiedSync();

        // 2. Google AI Inference (Image Embedding)
        final embedding = await ai.generateEmbedding(path);

        results.add(AssetEntity(
          path: path,
          creationDate: creationDate,
          cameraModel: exifData['Image Model']?.toString(),
          latitude: _parseGps(exifData['GPS GPSLatitude']),
          longitude: _parseGps(exifData['GPS GPSLongitude']),
          embedding: embedding,
        ));
      } catch (e) {
        print('MediaProcessor: Error processing $path - $e');
      }
    }
    return results;
  }

  static DateTime? _extractDate(Map<String, IfdTag> data) {
    final dateStr = data['Image DateTime']?.printable;
    if (dateStr == null) return null;
    try {
      final parts = dateStr.split(' ');
      final dateParts = parts[0].replaceAll(':', '-');
      return DateTime.tryParse('$dateParts ${parts[1]}');
    } catch (_) {
      return null;
    }
  }

  static double? _parseGps(IfdTag? tag) {
    if (tag == null) return null;
    // Standard EXIF GPS parsing logic
    return null; // Placeholder
  }
}

// Wrapper for compute if using Flutter's foundation compute
// Future<R> compute<Q, R>(computeCallback<Q, R> callback, Q message)
