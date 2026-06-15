import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:k_photo/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:geocoding/geocoding.dart';
import 'package:k_photo/core/network/kdrive_api_service.dart';
import 'package:exif/exif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AITaggingService {
  final AppDatabase _db;
  final KDriveApiService _api = KDriveApiService();
  static ImageLabeler? _labeler;
  bool _isProcessing = false;

  AITaggingService(this._db, [dynamic dummy]) {
    _labeler ??= ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
  }

  /// Verwerkt alle foto's die nog geen locatie of AI tags hebben.
  Future<void> processPendingPhotos({bool forceAll = false}) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final allPhotos = await _db.getAllPhotos();
      final pending = forceAll 
          ? allPhotos 
          : allPhotos.where((p) => 
              (p.locationName == null && p.latitude == null) || 
              p.aiTags.isEmpty
            ).toList();

      for (final photo in pending) {
        await processSinglePhoto(photo);
      }
    } catch (e) {
      debugPrint('AITaggingService: Fout bij batch verwerking: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Verwerkt een enkele foto.
  /// Gebruikt een 128KB fragment voor EXIF en de thumbnail voor AI Tags.
  Future<void> processSinglePhoto(Photo photo) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fragmentPath = p.join(tempDir.path, 'exif_frag_${photo.id}.tmp');
      
      // 1. EXIF extractie via 128KB fragment (snel en accuraat voor metadata)
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

      // 2. AI Labeling (alleen voor afbeeldingen)
      // We gebruiken de THUMBNAIL als die er is, dat voorkomt 'libjpeg error 105'
      if (photo.mediaType == 'image') {
        File? aiInputFile;
        if (photo.localThumbnailPath != null && File(photo.localThumbnailPath!).existsSync()) {
          aiInputFile = File(photo.localThumbnailPath!);
        }
        
        if (aiInputFile != null) {
          await _applyAiLabeling(photo, aiInputFile);
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
      
      if (labels != null && labels.isNotEmpty) {
        final List<String> newTags = labels
            .where((l) => l.confidence > 0.6)
            .map((l) => l.label.toLowerCase())
            .toList();
            
        if (newTags.isNotEmpty) {
          final Set<String> allTags = Set<String>.from(photo.aiTags);
          allTags.addAll(newTags);
          
          await (_db.update(_db.photos)..where((t) => t.id.equals(photo.id))).write(
            PhotosCompanion(aiTags: Value(allTags.toList())),
          );
        }
      }
    } catch (_) {
      // Fouten hier negeren we in productie
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

    // Update de foto met metadata. We gebruiken Value.absent() voor velden die we niet hebben
    // om te voorkomen dat we bestaande data overschrijven met null.
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

  void dispose() {
    _labeler?.close();
    _labeler = null;
  }
}
