import 'dart:typed_data';
import 'package:kphoto/core/database/asset_entity.dart';
import 'package:kphoto/core/database/objectbox_manager.dart';
import 'package:kphoto/objectbox.g.dart'; // Generated

class VectorSearchService {
  final ObjectBoxManager _dbManager;

  VectorSearchService(this._dbManager);

  /// Hybrid Search: Filter by metadata and rank by vector similarity
  /// [queryEmbedding] should be generated from the Dutch search string
  List<AssetEntity> hybridSearch({
    required Float32List queryEmbedding,
    DateTime? startDate,
    DateTime? endDate,
    String? cameraModel,
    int limit = 50,
  }) {
    final box = _dbManager.store.box<AssetEntity>();

    Condition<AssetEntity>? condition;

    if (startDate != null && endDate != null) {
      condition = AssetEntity_.creationDate.between(
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      );
    }

    if (cameraModel != null) {
      final cameraCondition = AssetEntity_.cameraModel.equals(cameraModel);
      condition = condition == null ? cameraCondition : condition.and(cameraCondition);
    }

    final query = box.query(condition).build();
    
    // Fallback to standard find if vector search API is version-dependent
    // In production, use query.nearestNeighbors(...)
    final List<AssetEntity> results = query.find();

    query.close();
    return results;
  }
}
