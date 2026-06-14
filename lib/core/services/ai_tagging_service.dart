import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:k_photo/core/database/app_database.dart';

class AITaggingService {
  final AppDatabase _db;
  late ImageLabeler _labeler;

  AITaggingService(this._db) {
    _labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.7));
  }

  Future<void> processPendingPhotos({bool forceAll = false}) async {
    final allPhotos = await _db.getAllPhotos();
    
    // Bij forceAll doen we alles, anders alleen foto's zonder tags
    final untaggedPhotos = forceAll 
        ? allPhotos.where((p) => p.localThumbnailPath != null).toList()
        : allPhotos.where((p) => p.aiTags.isEmpty && p.localThumbnailPath != null).toList();

    if (untaggedPhotos.isEmpty) return;
    
    debugPrint('AI Service: Starten met labelen van ${untaggedPhotos.length} foto\'s...');

    for (var photo in untaggedPhotos) {
      if (photo.localThumbnailPath == null) continue;
      final file = File(photo.localThumbnailPath!);
      if (!file.existsSync()) continue;

      try {
        final inputImage = InputImage.fromFilePath(photo.localThumbnailPath!);
        final List<ImageLabel> labels = await _labeler.processImage(inputImage);

        if (labels.isNotEmpty) {
          final Set<String> tags = {};
          for (var label in labels) {
            final name = label.label.toLowerCase();
            tags.add(name);
            
            // Voeg Nederlandse termen en categorieën toe voor betere zoekbaarheid
            if (_categoryMappings.containsKey(name)) {
              tags.addAll(_categoryMappings[name]!);
            }
          }
          
          await _db.updatePhotoTags(photo.id, tags.toList());
        }
      } catch (e) {
        // Log error
      }
    }
  }

  static const Map<String, List<String>> _categoryMappings = {
    'animal': ['dier'],
    'dog': ['hond', 'dier'],
    'cat': ['kat', 'dier'],
    'bird': ['vogel', 'dier'],
    'horse': ['paard', 'dier'],
    'elephant': ['olifant', 'dier'],
    'fish': ['vis', 'dier'],
    'insect': ['insect', 'dier'],
    'butterfly': ['vlinder', 'insect', 'dier'],
    'plant': ['plant'],
    'flower': ['bloem', 'plant'],
    'tree': ['boom', 'plant'],
    'grass': ['gras', 'plant'],
    'fruit': ['fruit', 'eten'],
    'forest': ['bos', 'natuur'],
    'mountain': ['berg', 'landschap'],
    'water': ['water', 'zee', 'meer'],
    'food': ['eten', 'voedsel'],
    'car': ['auto', 'voertuig'],
    'bicycle': ['fiets', 'voertuig'],
    'building': ['gebouw', 'architectuur'],
    'house': ['huis', 'gebouw'],
    'skyscraper': ['wolkenkrabber', 'stad'],
    
    // Wintersporten & Activiteiten
    'skiing': ['skiën', 'wintersport', 'sneeuw', 'sport'],
    'snowboarding': ['snowboarden', 'wintersport', 'sneeuw', 'sport'],
    'ice skating': ['schaatsen', 'wintersport', 'ijs', 'sport'],
    'skating': ['schaatsen', 'sport'],
    'snow': ['sneeuw', 'winter'],
    'ice': ['ijs', 'winter'],
    'hockey': ['hockey', 'sport'],
    
    // Zomersporten & Activiteiten
    'surfing': ['surfen', 'watersport', 'zee', 'zomer', 'sport'],
    'swimming': ['zwemmen', 'watersport', 'water', 'zomer', 'sport'],
    'sailing': ['zeilen', 'watersport', 'boot', 'water', 'zomer'],
    'hiking': ['wandelen', 'natuur', 'buiten', 'sport'],
    'cycling': ['fietsen', 'wielrennen', 'sport', 'voertuig'],
    'running': ['hardlopen', 'sport'],
    'football': ['voetbal', 'sport'],
    'soccer': ['voetbal', 'sport'],
    'tennis': ['tennis', 'sport'],
    'basketball': ['basketbal', 'sport'],
    'golf': ['golf', 'sport'],
    'camping': ['kamperen', 'vakantie', 'buiten'],
    'tent': ['tent', 'kamperen', 'buiten'],
    'beach': ['strand', 'zee', 'zomer', 'vakantie'],
    'sun': ['zon', 'zomer'],
  };

  void dispose() {
    _labeler.close();
  }
}
