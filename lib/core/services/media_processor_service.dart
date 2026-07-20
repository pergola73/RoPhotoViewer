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

import 'package:flutter/services.dart';

class MediaProcessorService {
  final ObjectBoxManager _dbManager;
  bool _isProcessing = false;

  MediaProcessorService(this._dbManager);

  Future<void> processNewFiles(List<String> filePaths, {Function(int, int)? onProgress}) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final box = _dbManager.store.box<AssetEntity>();
      
      final query = box.query().build();
      final existingPaths = query.property(AssetEntity_.path).find().toSet();
      query.close();

      // We filteren vliegensvlug de lijst van 35.000 fotos
      final pendingPaths = filePaths.where((p) {
        return p.isNotEmpty && !existingPaths.contains(p);
      }).toList();
      
      if (pendingPaths.isEmpty) {
        debugPrint('MediaProcessor: Alles is al geïndexeerd in ObjectBox.');
        _isProcessing = false;
        return;
      }

      debugPrint('MediaProcessor: ${pendingPaths.length} nieuwe bestanden te indexeren');

      // CRUCIAAL: Haal de token van de hoofd-thread op
      final RootIsolateToken rootToken = RootIsolateToken.instance!;

      const int batchSize = 25; // Iets kleiner voor stabiliteit op grote aantallen
      int processed = 0;
      
      for (int i = 0; i < pendingPaths.length; i += batchSize) {
        final batch = pendingPaths.skip(i).take(batchSize).toList();
        
        // Geef de token mee aan de worker
        final List<AssetEntity> processedAssets = await compute(_processBatch, {
          'paths': batch,
          'token': rootToken,
        });
        
        if (processedAssets.isNotEmpty) {
          box.putMany(processedAssets);
        }
        
        processed += batch.length;
        onProgress?.call(processed, pendingPaths.length);
      }
    } catch (e) {
      debugPrint('MediaProcessor: Fout tijdens verwerking - $e');
    } finally {
      _isProcessing = false;
    }
  }

  // Deze worker draait in zijn eigen isolate
  static Future<List<AssetEntity>> _processBatch(Map<String, dynamic> args) async {
    final List<String> paths = args['paths'];
    final RootIsolateToken token = args['token'];
    
    // VERBINDING MAKEN: Autoriseer dit achtergrond-kamertje
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    
    List<AssetEntity> results = [];
    final ai = ImageEmbeddingService();
    await ai.init(); // Model laden binnen de isolate

    for (var path in paths) {
      try {
        final file = File(path);
        if (!file.existsSync()) continue;
        
        // Google AI Analyse
        final embedding = await ai.generateEmbedding(path);

        if (embedding.isNotEmpty) {
          results.add(AssetEntity(
            path: path,
            creationDate: file.lastModifiedSync(),
            embedding: embedding,
          ));
        }
        
        // Geef het systeem even ademruimte tussen zware AI taken
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        print('MediaProcessor Isolate Error: $e');
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
