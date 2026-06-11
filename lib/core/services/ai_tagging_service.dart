import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:ro_photo_viewer/core/database/app_database.dart';

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
          final tags = labels.map((l) => l.label.toLowerCase()).toList();
          await _db.updatePhotoTags(photo.id, tags);
        }
      } catch (e) {
        // Log error in a production app
      }
    }
  }

  void dispose() {
    _labeler.close();
  }
}
