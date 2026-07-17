import 'dart:convert';
import 'package:flutter/services.dart';

class ClipTokenizer {
  Map<String, int> _byteEncoder = {};
  Map<String, int> _vocab = {};
  static const int _maxTokenLength = 77;

  ClipTokenizer._();
  static final ClipTokenizer instance = ClipTokenizer._();

  Future<void> init() async {
    if (_vocab.isNotEmpty) return;
    try {
      // Probeer eerst .json
      try {
        final vocabStr = await rootBundle.loadString('assets/models/clip_vocab.json');
        _vocab = Map<String, int>.from(json.decode(vocabStr));
        return;
      } catch (_) {}

      // Anders probeer .txt (één woord per regel, index is de regel-id)
      final vocabStr = await rootBundle.loadString('assets/models/clip_vocab.txt');
      final lines = vocabStr.split('\n');
      for (int i = 0; i < lines.length; i++) {
        _vocab[lines[i].trim()] = i;
      }
    } catch (e) {
      print('ClipTokenizer: Waarschuwing - Kon vocab niet laden, gebruik minimale fallback.');
      _vocab = {'<|startoftext|>': 49406, '<|endoftext|>': 49407};
    }
  }

  List<int> tokenize(String text) {
    // Basis opschoning voor Nederlandse tekst
    final cleanText = text.toLowerCase().trim();
    final List<int> tokens = [_vocab['<|startoftext|>'] ?? 49406];
    
    // Eenvoudige woord-naar-id mapping (BPE Lite)
    final words = cleanText.split(RegExp(r'\s+'));
    for (var word in words) {
      if (_vocab.containsKey(word)) {
        tokens.add(_vocab[word]!);
      } else {
        // Als woord niet bestaat, proberen we letters (fallback)
        for (var char in word.split('')) {
          if (_vocab.containsKey(char)) tokens.add(_vocab[char]!);
        }
      }
    }

    tokens.add(_vocab['<|endoftext|>'] ?? 49407);

    // Aanvullen tot 77 tokens (vereist door CLIP)
    final result = List<int>.filled(_maxTokenLength, 0);
    for (int i = 0; i < tokens.length && i < _maxTokenLength; i++) {
      result[i] = tokens[i];
    }

    return result;
  }
}
