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
  static const String _modelUrl = 'https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/image_embedder/android/mobilenet_v3_large.tflite';

  static final ImageEmbeddingService _instance = ImageEmbeddingService._internal();
  factory ImageEmbeddingService() => _instance;
  ImageEmbeddingService._internal();

  Future<void> init() async {
    if (_isReady) return;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final modelPath = p.join(docsDir.path, 'image_embedder.tflite');
      final modelFile = File(modelPath);

      // 1. Check of model lokaal aanwezig is, anders downloaden
      if (!modelFile.existsSync()) {
        debugPrint('Google AI: Model downloaden van Google Cloud...');
        // Gebruik een langere timeout en betere progress voor downloads
        await Dio().download(
          _modelUrl, 
          modelPath,
          options: Options(receiveTimeout: const Duration(minutes: 5)),
        );
        debugPrint('Google AI: Download voltooid.');
      }

      // 2. Interpreter laden
      final options = InterpreterOptions()..threads = 4;
      _interpreter = Interpreter.fromFile(modelFile, options: options);
      _isReady = true;
      debugPrint('Google AI: Zoekmachine is klaar voor gebruik (1024-dim).');
    } catch (e) {
      debugPrint('Google AI: Initialisatie mislukt - $e');
    }
  }

  Future<Float32List> generateEmbedding(String imagePath) async {
    if (!_isReady) await init();
    if (_interpreter == null) return Float32List(1024);

    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return Float32List(1024);

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

      var output = List<double>.filled(1024, 0).reshape([1, 1024]);
      _interpreter!.run(input.reshape([1, 224, 224, 3]), output);

      return Float32List.fromList(output[0].cast<double>());
    } catch (e) {
      debugPrint('Google AI: Fout bij analyse van $imagePath - $e');
      return Float32List(1024);
    }
  }
}
