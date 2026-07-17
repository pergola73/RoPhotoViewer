import 'dart:typed_data';
import 'package:objectbox/objectbox.dart';

@Entity()
class AssetEntity {
  @Id()
  int id = 0;

  @Index()
  String path;

  @Property(type: PropertyType.date)
  DateTime creationDate;

  double? latitude;
  double? longitude;

  @Index()
  String? cameraModel;

  String? textOCR;

  @Property(type: PropertyType.floatVector)
  @HnswIndex(dimensions: 1024) // Google MobileNet-v3 Large gebruikt 1024 dimensies
  Float32List? embedding;

  AssetEntity({
    required this.path,
    required this.creationDate,
    this.latitude,
    this.longitude,
    this.cameraModel,
    this.textOCR,
    this.embedding,
  });
}
