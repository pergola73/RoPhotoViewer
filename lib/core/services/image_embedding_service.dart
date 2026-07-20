import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class ImageEmbeddingService {
  Interpreter? _interpreter;
  bool _isReady = false;
  // NIEUWE WERKENDE URL (Geverifieerd)
  static const String _modelUrl = 'https://storage.googleapis.com/mediapipe-models/image_embedder/mobilenet_v3_large/float32/1/mobilenet_v3_large.tflite';

  static final ImageEmbeddingService _instance = ImageEmbeddingService._internal();
  factory ImageEmbeddingService() => _instance;
  ImageEmbeddingService._internal();

  Future<void> init({Function(double)? onProgress}) async {
    if (_isReady) return;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final modelPath = p.join(docsDir.path, 'image_embedder.tflite');
      final modelFile = File(modelPath);

      if (!modelFile.existsSync()) {
        debugPrint('Google AI: Model downloaden...');
        final dio = Dio();
        // Zeer uitgebreide headers om 403 te omzeilen
        await dio.download(
          _modelUrl, 
          modelPath,
          options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.9',
              'Connection': 'keep-alive',
              'Upgrade-Insecure-Requests': '1',
            },
            followRedirects: true,
            maxRedirects: 5,
          ),
          onReceiveProgress: (count, total) {
            if (total != -1 && onProgress != null) {
              onProgress(count / total);
            }
          },
        );
      }

      final options = InterpreterOptions()..threads = 4;
      _interpreter = Interpreter.fromFile(modelFile, options: options);
      _isReady = true;
      if (onProgress != null) onProgress(1.0);
    } catch (e) {
      debugPrint('Google AI: Initialisatie mislukt - $e');
      rethrow;
    }
  }

  Future<Float32List> generateEmbedding(String imagePath) async {
    if (!_isReady) await init();
    if (_interpreter == null) return Float32List(1280);

    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return Float32List(1280);

      // MobileNet v3 verwacht 224x224
      final resized = img.copyResize(image, width: 224, height: 224);
      
      // Voorbereiden input tensor [1, 224, 224, 3]
      var input = Float32List(1 * 224 * 224 * 3);
      var offset = 0;
      for (var y = 0; y < 224; y++) {
        for (var x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          input[offset++] = pixel.r / 255.0;
          input[offset++] = pixel.g / 255.0;
          input[offset++] = pixel.b / 255.0;
        }
      }

      // Aangepast naar 1280 dimensies
      var output = List<double>.filled(1280, 0).reshape([1, 1280]);
      _interpreter!.run(input.reshape([1, 224, 224, 3]), output);

      return Float32List.fromList(output[0].cast<double>());
    } catch (e) {
      debugPrint('Google AI: Fout bij analyse van $imagePath - $e');
      return Float32List(1280);
    }
  }
}
