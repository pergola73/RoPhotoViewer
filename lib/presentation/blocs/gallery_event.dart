part of 'gallery_bloc.dart';

abstract class GalleryEvent extends Equatable {
  const GalleryEvent();

  @override
  List<Object?> get props => [];
}

class LoadGallery extends GalleryEvent {}

class LoadMorePhotos extends GalleryEvent {}

class PhotosUpdated extends GalleryEvent {
  final List<Photo> photos;
  const PhotosUpdated(this.photos);

  @override
  List<Object?> get props => [photos];
}

class SyncProgressUpdated extends GalleryEvent {
  final int count;
  final SyncPhase? phase;
  const SyncProgressUpdated(this.count, {this.phase});

  @override
  List<Object?> get props => [count, phase];
}

class SearchGallery extends GalleryEvent {
  final String query;
  const SearchGallery(this.query);

  @override
  List<Object?> get props => [query];
}

class SemanticSearch extends GalleryEvent {
  final String query;
  const SemanticSearch(this.query);

  @override
  List<Object?> get props => [query];
}

class ChangeViewMode extends GalleryEvent {
  final GalleryViewMode mode;
  const ChangeViewMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

class TogglePhotoSelection extends GalleryEvent {
  final int photoId;
  const TogglePhotoSelection(this.photoId);

  @override
  List<Object?> get props => [photoId];
}

class ClearSelection extends GalleryEvent {}

class SelectAll extends GalleryEvent {}

class SelectSection extends GalleryEvent {
  final List<int> photoIds;
  const SelectSection(this.photoIds);

  @override
  List<Object?> get props => [photoIds];
}

class DeleteSelectedPhotos extends GalleryEvent {
  final bool remoteToo;
  final bool permanent;
  const DeleteSelectedPhotos({required this.remoteToo, this.permanent = false});

  @override
  List<Object?> get props => [remoteToo, permanent];
}

class LoadTrash extends GalleryEvent {}

class RestoreSelectedFromTrash extends GalleryEvent {}

class ToggleTrashSelection extends GalleryEvent {
  final String itemId;
  const ToggleTrashSelection(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class ClearTrashSelection extends GalleryEvent {}

class DeleteSelectedFromTrash extends GalleryEvent {
  final bool permanent;
  const DeleteSelectedFromTrash({this.permanent = true});

  @override
  List<Object?> get props => [permanent];
}

class EmptyTrash extends GalleryEvent {}

class ToggleFavoriteFilter extends GalleryEvent {}

class ToggleSelectedPhotosFavorite extends GalleryEvent {}

class SyncWithKDrive extends GalleryEvent {
  final bool isManual;
  const SyncWithKDrive({this.isManual = false});

  @override
  List<Object?> get props => [isManual];
}

class UpdatePhotoMetadata extends GalleryEvent {
  final int photoId;
  final DateTime? date;
  final String? keywords;
  const UpdatePhotoMetadata(this.photoId, {this.date, this.keywords});

  @override
  List<Object?> get props => [photoId, date, keywords];
}

class StartAiScan extends GalleryEvent {
  final bool forceAll;
  const StartAiScan({this.forceAll = false});

  @override
  List<Object?> get props => [forceAll];
}

class AiScanProgressUpdated extends GalleryEvent {
  final int current;
  final int total;
  const AiScanProgressUpdated(this.current, this.total);

  @override
  List<Object?> get props => [current, total];
}

class AiScanFinished extends GalleryEvent {}

class IndexingProgressUpdated extends GalleryEvent {
  final int current;
  final int total;
  const IndexingProgressUpdated(this.current, this.total);

  @override
  List<Object?> get props => [current, total];
}

class IndexingFinished extends GalleryEvent {}
