import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:kphoto/core/services/clip_tokenizer.dart';
import 'package:image/image.dart' as img;

class ClipService {
  Interpreter? _visualInterpreter;
  Interpreter? _textInterpreter;
  bool _isInitialized = false;

  // CLIP Normalisatie constanten
  static const List<double> _mean = [0.48145466, 0.4578275, 0.40821073];
  static const List<double> _std = [0.26862954, 0.26130258, 0.27577711];

  static final ClipService _instance = ClipService._internal();
  factory ClipService() => _instance;
  ClipService._internal();

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final options = InterpreterOptions()..threads = 4;
      
      // Laad visuele encoder
      _visualInterpreter = await Interpreter.fromAsset(
        'assets/models/clip_visual.tflite', 
        options: options
      );
      
      // Laad tekst encoder
      _textInterpreter = await Interpreter.fromAsset(
        'assets/models/clip_text.tflite', 
        options: options
      );

      await ClipTokenizer.instance.init();
      _isInitialized = true;
    } catch (e) {
      print('ClipService: Initialisatie mislukt - $e');
    }
  }

  /// Genereert een vector voor een afbeelding
  Future<Float32List> generateImageEmbedding(String imagePath) async {
    if (!_isInitialized) await init();
    if (_visualInterpreter == null) return Float32List(512);

    try {
      // 1. Resize en decodeer afbeelding
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return Float32List(512);

      final resized = img.copyResize(image, width: 224, height: 224);
      
      // 2. Normalisatie: omzetten naar Float32 [1, 224, 224, 3]
      var input = Float32List(1 * 224 * 224 * 3);
      var buffer = input.buffer;
      var offset = 0;

      for (var y = 0; y < 224; y++) {
        for (var x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          // Normaliseer R, G, B kanalen
          input[offset++] = (pixel.r / 255.0 - _mean[0]) / _std[0];
          input[offset++] = (pixel.g / 255.0 - _mean[1]) / _std[1];
          input[offset++] = (pixel.b / 255.0 - _mean[2]) / _std[2];
        }
      }

      // 3. Model uitvoeren
      var output = List<double>.filled(512, 0).reshape([1, 512]);
      _visualInterpreter!.run(input.reshape([1, 224, 224, 3]), output);

      return Float32List.fromList(output[0].cast<double>());
    } catch (e) {
      print('ClipService: Fout bij afbeelding embedding - $e');
      return Float32List(512);
    }
  }

  /// Genereert een vector voor een (Nederlandse) zoektekst
  Future<Float32List> generateTextEmbedding(String text) async {
    if (!_isInitialized) await init();
    if (_textInterpreter == null) return Float32List(512);

    try {
      final translatedText = _translateDutchToEnglish(text);
      debugPrint('ClipService: Zoeken op "$text" (Vertaald: "$translatedText")');

      final tokens = ClipTokenizer.instance.tokenize(translatedText);
      var input = [tokens]; 
      var output = List<double>.filled(512, 0).reshape([1, 512]);

      _textInterpreter!.run(input, output);
      return Float32List.fromList(output[0].cast<double>());
    } catch (e) {
      print('ClipService: Fout bij tekst embedding - $e');
      return Float32List(512);
    }
  }

  String _translateDutchToEnglish(String text) {
    final Map<String, String> simpleDict = {
      'hond': 'dog',
      'kat': 'cat',
      'strand': 'beach',
      'zee': 'sea',
      'bos': 'forest',
      'auto': 'car',
      'eten': 'food',
      'drinken': 'drink',
      'feest': 'party',
      'vakantie': 'vacation',
      'bergen': 'mountains',
      'sneeuw': 'snow',
      'zon': 'sun',
      'zonsondergang': 'sunset',
      'bloemen': 'flowers',
      'park': 'park',
      'stad': 'city',
      'gebouw': 'building',
      'kind': 'child',
      'baby': 'baby',
      'familie': 'family',
    };
    
    String translated = text.toLowerCase();
    simpleDict.forEach((nl, en) {
      translated = translated.replaceAll(nl, en);
    });
    return translated;
  }
}
