import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:k_photo/core/database/app_database.dart';

class AITaggingService {
  final AppDatabase _db;
  late ImageLabeler _labeler;

  AITaggingService(this._db) {
    _labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.7));
  }

  Future<void> processPendingPhotos() async {
    final allPhotos = await _db.getAllPhotos();
    final untaggedPhotos = allPhotos.where((p) => p.aiTags.isEmpty).toList();

    for (var photo in untaggedPhotos) {
      if (photo.localThumbnailPath == null) continue;

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
    'beach': ['strand', 'zee'],
    'food': ['eten', 'voedsel'],
    'car': ['auto', 'voertuig'],
    'bicycle': ['fiets', 'voertuig'],
    'building': ['gebouw', 'architectuur'],
    'house': ['huis', 'gebouw'],
    'skyscraper': ['wolkenkrabber', 'stad'],
  };

  void dispose() {
    _labeler.close();
  }
}
