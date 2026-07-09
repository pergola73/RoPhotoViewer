import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:kphoto/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:geocoding/geocoding.dart';
import 'package:kphoto/core/network/kdrive_api_service.dart';
import 'package:exif/exif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

class AITaggingService {
  final AppDatabase _db;
  final KDriveApiService _api = KDriveApiService();
  static ImageLabeler? _labeler;
  static FaceDetector? _faceDetector;
  bool _isProcessing = false;

  AITaggingService(this._db, [dynamic dummy]) {
    _labeler ??= ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.4));
    _faceDetector ??= FaceDetector(options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
    ));
  }

  Future<void> processPendingPhotos({
    bool forceAll = false,
    Function(int current, int total)? onProgress,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final allPhotos = await _db.getAllPhotos();
      final pending = forceAll 
          ? allPhotos 
          : allPhotos.where((p) => 
              (p.locationName == null && p.latitude == null) || 
              p.aiTags.isEmpty ||
              p.keywords == null
            ).toList();

      int count = 0;
      for (final photo in pending) {
        if (forceAll) {
          final List<String> translatedTags = photo.aiTags.map((tag) => _translateToDutch(tag)).toList();
          await (_db.update(_db.photos)..where((t) => t.id.equals(photo.id))).write(
            PhotosCompanion(aiTags: Value(translatedTags)),
          );
        }
        await processSinglePhoto(photo);
        count++;
        onProgress?.call(count, pending.length);
      }
    } catch (e) {
      debugPrint('AITaggingService: Fout bij batch verwerking: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> processSinglePhoto(Photo photo) async {
    try {
      final tempDir = await getTemporaryDirectory();
      
      final fragmentPath = p.join(tempDir.path, 'exif_frag_${photo.id}.tmp');
      final pBytes = await _api.downloadPartialFile(photo.kdrivePath, bytes: 131072);
      if (pBytes != null) {
        final file = File(fragmentPath);
        await file.writeAsBytes(pBytes);
        final data = await readExifFromFile(file);
        if (data.isNotEmpty) {
          await _saveMetadataAndLocation(photo, data);
        }
        if (await file.exists()) await file.delete();
      }

      if (photo.mediaType == 'image') {
        File? aiInputFile;
        bool isLargeFragment = false;

        final aiFragBytes = await _api.downloadPartialFile(photo.kdrivePath, bytes: 1572864);
        if (aiFragBytes != null) {
          final aiFile = File(p.join(tempDir.path, 'ai_large_${photo.id}.tmp'));
          await aiFile.writeAsBytes(aiFragBytes);
          aiInputFile = aiFile;
          isLargeFragment = true;
        } else if (photo.localThumbnailPath != null && File(photo.localThumbnailPath!).existsSync()) {
          aiInputFile = File(photo.localThumbnailPath!);
        }
        
        if (aiInputFile != null) {
          await _applyAiLabeling(photo, aiInputFile);
          if (isLargeFragment && await aiInputFile.exists()) {
            await aiInputFile.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('AITaggingService: Fout bij verwerken van ${photo.fileName}: $e');
    }
  }

  Future<void> _applyAiLabeling(Photo photo, File file) async {
    try {
      final inputImage = InputImage.fromFile(file);
      final labels = await _labeler?.processImage(inputImage);
      final faces = await _faceDetector?.processImage(inputImage);
      
      final Set<String> allTags = Set<String>.from(photo.aiTags);

      if (labels != null && labels.isNotEmpty) {
        final List<String> newTags = labels
            .where((l) => l.confidence > 0.45)
            .map((l) => _translateToDutch(l.label))
            .toList();
            
        for (var tag in newTags) {
          if (tag.isNotEmpty) allTags.add(tag.toLowerCase());
        }
      }

      if (faces != null && faces.isNotEmpty) {
        allTags.add('persoon');
        if (faces.length > 1) allTags.add('groep');
        await _saveDetectedFaces(photo, file, faces);
      }
      
      await (_db.update(_db.photos)..where((t) => t.id.equals(photo.id))).write(
        PhotosCompanion(aiTags: Value(allTags.toList())),
      );
    } catch (_) {}
  }

  Future<void> _saveDetectedFaces(Photo photo, File sourceFile, List<Face> faces) async {
    try {
      await (_db.delete(_db.detectedFaces)..where((t) => t.photoId.equals(photo.id))).go();

      final bytes = await sourceFile.readAsBytes();
      final img.Image? fullImage = img.decodeImage(bytes);
      if (fullImage == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final facesDir = Directory(p.join(appDir.path, 'faces'));
      if (!facesDir.existsSync()) facesDir.createSync(recursive: true);

      for (var face in faces) {
        final rect = face.boundingBox;
        final int margin = (rect.width * 0.1).toInt();
        final faceCrop = img.copyCrop(
          fullImage,
          x: (rect.left - margin).toInt().clamp(0, fullImage.width),
          y: (rect.top - margin).toInt().clamp(0, fullImage.height),
          width: (rect.width + margin * 2).toInt().clamp(0, fullImage.width),
          height: (rect.height + margin * 2).toInt().clamp(0, fullImage.height),
        );

        final facePath = p.join(facesDir.path, 'face_${photo.id}_${DateTime.now().microsecondsSinceEpoch}.jpg');
        await File(facePath).writeAsBytes(img.encodeJpg(faceCrop, quality: 90));

        await _db.addDetectedFace(DetectedFacesCompanion.insert(
          photoId: photo.id,
          x: rect.left,
          y: rect.top,
          width: rect.width,
          height: rect.height,
          faceThumbnailPath: Value(facePath),
        ));
      }
    } catch (e) {
      debugPrint('AITaggingService: Fout bij opslaan gezichten: $e');
    }
  }

  Future<void> _saveMetadataAndLocation(Photo photo, Map<String, IfdTag> data) async {
    double? lat;
    double? lon;
    
    final latitude = data['GPS GPSLatitude'];
    final latitudeRef = data['GPS GPSLatitudeRef'];
    final longitude = data['GPS GPSLongitude'];
    final longitudeRef = data['GPS GPSLongitudeRef'];

    if (latitude != null && latitudeRef != null && longitude != null && longitudeRef != null) {
      lat = _convertTagToDouble(latitude);
      if (latitudeRef.printable == 'S' && lat != null) lat = -lat;

      lon = _convertTagToDouble(longitude);
      if (longitudeRef.printable == 'W' && lon != null) lon = -lon;
    }

    String? locName;
    final Set<String> tags = Set<String>.from(photo.aiTags);

    if (lat != null && lon != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon).timeout(const Duration(seconds: 10));
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          locName = p.country != null ? '${p.locality}, ${p.country}' : p.locality;
          if (p.locality != null) tags.add(p.locality!.toLowerCase());
          if (p.country != null) tags.add(p.country!.toLowerCase());
        }
      } catch (_) {}
    }

    final String? make = data['Image Make']?.printable;
    final String? model = data['Image Model']?.printable;
    final String? camera = (make != null && model != null) 
        ? (model.contains(make) ? model : '$make $model') 
        : (model ?? make);

    String? extractedKeywords;
    final xpKeywords = data['Image XPKeywords'];
    final imageDescription = data['Image ImageDescription'];
    final userComment = data['EXIF UserComment'];

    if (xpKeywords != null) {
      try {
        if (xpKeywords.values is List<int>) {
          final values = xpKeywords.values;
          extractedKeywords = String.fromCharCodes((values as List<int>).where((c) => c != 0));
        } else {
          extractedKeywords = xpKeywords.printable;
        }
      } catch (_) {
        extractedKeywords = xpKeywords.printable;
      }
    } else if (imageDescription != null && imageDescription.printable.isNotEmpty) {
      extractedKeywords = imageDescription.printable;
    } else if (userComment != null && userComment.printable.isNotEmpty) {
      extractedKeywords = userComment.printable;
    }

    await (_db.update(_db.photos)..where((t) => t.id.equals(photo.id))).write(
      PhotosCompanion(
        latitude: lat != null ? Value(lat) : const Value.absent(),
        longitude: lon != null ? Value(lon) : const Value.absent(),
        locationName: locName != null ? Value(locName) : const Value.absent(),
        aiTags: Value(tags.toList()),
        cameraModel: camera != null ? Value(camera) : const Value.absent(),
        exposureTime: data['EXIF ExposureTime'] != null ? Value(data['EXIF ExposureTime']?.printable) : const Value.absent(),
        fNumber: data['EXIF FNumber'] != null ? Value('f/${data['EXIF FNumber']?.printable}') : const Value.absent(),
        iso: data['EXIF ISOSpeedRatings'] != null ? Value(int.tryParse(data['EXIF ISOSpeedRatings']?.printable ?? '')) : const Value.absent(),
        focalLength: data['EXIF FocalLength'] != null ? Value('${data['EXIF FocalLength']?.printable}mm') : const Value.absent(),
        keywords: extractedKeywords != null ? Value(extractedKeywords) : const Value.absent(),
      ),
    );
  }

  double? _convertTagToDouble(IfdTag tag) {
    try {
      final values = tag.values.toList();
      if (values.length == 3) {
        return _ratioToDouble(values[0]) + (_ratioToDouble(values[1]) / 60.0) + (_ratioToDouble(values[2]) / 3600.0);
      }
    } catch (_) {}
    return null;
  }

  double _ratioToDouble(dynamic ratio) {
    if (ratio is num) return ratio.toDouble();
    try { return ratio.numerator / ratio.denominator; } catch (_) { return 0.0; }
  }

  String _translateToDutch(String label) {
    final Map<String, String> translations = {
      'sky': 'Lucht',
      'water': 'Water',
      'tree': 'Boom',
      'plant': 'Plant',
      'flower': 'Bloem',
      'dog': 'Hond',
      'cat': 'Kat',
      'human': 'Persoon',
      'person': 'Persoon',
      'man': 'Man',
      'woman': 'Vrouw',
      'building': 'Gebouw',
      'house': 'Huis',
      'car': 'Auto',
      'vehicle': 'Voertuig',
      'cloud': 'Wolk',
      'nature': 'Natuur',
      'landscape': 'Landschap',
      'mountain': 'Berg',
      'beach': 'Strand',
      'sea': 'Zee',
      'ocean': 'Oceaan',
      'forest': 'Bos',
      'grass': 'Gras',
      'field': 'Veld',
      'food': 'Eten',
      'drink': 'Drinken',
      'plate': 'Bord',
      'table': 'Tafel',
      'chair': 'Stoel',
      'furniture': 'Meubels',
      'interior': 'Interieur',
      'room': 'Kamer',
      'window': 'Raam',
      'door': 'Deur',
      'street': 'Straat',
      'road': 'Weg',
      'city': 'Stad',
      'urban': 'Stedelijk',
      'architecture': 'Architectuur',
      'travel': 'Reizen',
      'vacation': 'Vakantie',
      'sun': 'Zon',
      'sunset': 'Zonsondergang',
      'sunrise': 'Zonsopkomst',
      'night': 'Nacht',
      'light': 'Licht',
      'dark': 'Donker',
      'color': 'Kleur',
      'blue': 'Blauw',
      'green': 'Groen',
      'red': 'Rood',
      'yellow': 'Geel',
      'white': 'Wit',
      'black': 'Zwart',
      'animal': 'Dier',
      'bird': 'Vogel',
      'fish': 'Vis',
      'insect': 'Insect',
      'mammal': 'Zoogdier',
      'pet': 'Huisdier',
      'technology': 'Technologie',
      'computer': 'Computer',
      'laptop': 'Laptop',
      'phone': 'Telefoon',
      'camera': 'Camera',
      'art': 'Kunst',
      'painting': 'Schilderij',
      'drawing': 'Tekening',
      'text': 'Tekst',
      'writing': 'Schrijven',
      'book': 'Boek',
      'paper': 'Papier',
      'music': 'Muziek',
      'sport': 'Sport',
      'game': 'Spel',
      'toy': 'Speelgoed',
      'child': 'Kind',
      'baby': 'Baby',
      'couple': 'Stel',
      'family': 'Familie',
      'friend': 'Vriend',
      'wedding': 'Bruiloft',
      'party': 'Feest',
      'event': 'Evenement',
      'wood': 'Hout',
      'snow': 'Sneeuw',
      'ice': 'IJs',
      'fire': 'Vuur',
      'smile': 'Glimlach',
      'face': 'Gezicht',
      'clothing': 'Kleding',
      'shoe': 'Schoen',
      'hat': 'Hoed',
      'bag': 'Tas',
      'bicycle': 'Fiets',
      'motorcycle': 'Motor',
      'boat': 'Boot',
      'airplane': 'Vliegtuig',
      'train': 'Trein',
      'bridge': 'Brug',
      'tower': 'Toren',
      'park': 'Park',
      'garden': 'Tuin',
      'desert': 'Woestijn',
      'shore': 'Kust',
      'river': 'Rivier',
      'lake': 'Meer',
      'rock': 'Rots',
      'stone': 'Steen',
      'sand': 'Zand',
      'wildlife': 'Wilde dieren',
      'vertebrate': 'Gewervelde',
      'canidae': 'Hondachtige',
      'felidae': 'Katachtige',
      'outdoor': 'Buiten',
    };
    final String searchLabel = label.toLowerCase();
    return translations[searchLabel] ?? label;
  }

  void dispose() {
    _labeler?.close();
    _labeler = null;
    _faceDetector?.close();
    _faceDetector = null;
  }
}
