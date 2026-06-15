import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:k_photo/core/database/app_database.dart';

class AITaggingService {
  final AppDatabase _db;
  static ImageLabeler? _labeler;

  AITaggingService(this._db) {
    _labeler ??= ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
  }

  Future<void> processPendingPhotos({bool forceAll = false}) async {
    final allPhotos = await _db.getAllPhotos();
    
    final untaggedPhotos = forceAll 
        ? allPhotos.where((p) => p.localThumbnailPath != null).toList()
        : allPhotos.where((p) => p.aiTags.isEmpty && p.localThumbnailPath != null).toList();

    if (untaggedPhotos.isEmpty) return;
    
    debugPrint('AI Service: Verwerken van ${untaggedPhotos.length} thumbnails...');

    for (var photo in untaggedPhotos) {
      await _processSinglePhoto(photo);
    }
  }

  Future<void> processSinglePhoto(Photo photo) async {
    if (photo.localThumbnailPath == null) return;
    final file = File(photo.localThumbnailPath!);
    if (!file.existsSync()) {
      debugPrint('AI Service: Thumbnail niet gevonden voor ${photo.fileName}');
      return;
    }

    try {
      debugPrint('AI Service: Scannen van ${photo.fileName}...');
      final inputImage = InputImage.fromFilePath(photo.localThumbnailPath!);
      final List<ImageLabel> labels = await _labeler!.processImage(inputImage);

      // Haal huidige tags op om te voorkomen dat we locatie-tags overschrijven
      final existingPhoto = await (_db.select(_db.photos)..where((t) => t.id.equals(photo.id))).getSingleOrNull();
      final Set<String> tags = existingPhoto != null ? Set<String>.from(existingPhoto.aiTags) : {};

      if (labels.isNotEmpty) {
        for (var label in labels) {
          final name = label.label.toLowerCase();
          tags.add(name);
          if (_categoryMappings.containsKey(name)) {
            tags.addAll(_categoryMappings[name]!);
          }
        }
        await _db.updatePhotoTags(photo.id, tags.toList());
        debugPrint('AI Service: ${tags.length} tags nu gekoppeld aan ${photo.fileName}');
      } else {
        debugPrint('AI Service: Geen labels gevonden voor ${photo.fileName}');
      }
    } catch (e) {
      debugPrint('AI Service: Fout bij scannen van ${photo.fileName}: $e');
    }
  }

  Future<void> _processSinglePhoto(Photo photo) async {
    return processSinglePhoto(photo);
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
    
    // Mensen & Portretten
    'person': ['persoon', 'mensen'],
    'face': ['gezicht', 'portret'],
    'smile': ['lach', 'mensen'],
    'crowd': ['mensen', 'groep'],
    'baby': ['baby', 'kind'],
    'child': ['kind'],
    
    // Interieur & Voorwerpen
    'furniture': ['meubels', 'interieur'],
    'table': ['tafel', 'interieur'],
    'chair': ['stoel', 'interieur'],
    'bed': ['bed', 'interieur'],
    'kitchen': ['keuken', 'binnen'],
    'computer': ['computer', 'technologie'],
    'phone': ['telefoon', 'technologie'],
    'book': ['boek', 'lezen'],
    'clock': ['klok', 'tijd'],
    
    // Kleding
    'clothing': ['kleding'],
    'hat': ['hoed', 'kleding'],
    'shoes': ['schoenen', 'kleding'],
    'dress': ['jurk', 'kleding'],
    
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
    
    // Overige
    'bridge': ['brug', 'architectuur'],
    'street': ['straat', 'stad'],
    'park': ['park', 'natuur'],
    'instrument': ['instrument', 'muziek'],
    'guitar': ['gitaar', 'muziek'],
    'piano': ['piano', 'muziek'],
    'painting': ['schilderij', 'kunst'],
    'statue': ['beeld', 'kunst'],
  };

  void dispose() {
    _labeler?.close();
    _labeler = null;
  }
}
