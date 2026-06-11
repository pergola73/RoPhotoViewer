part of 'gallery_bloc.dart';

abstract class GalleryEvent extends Equatable {
  const GalleryEvent();

  @override
  List<Object?> get props => [];
}

class LoadGallery extends GalleryEvent {}

class PhotosUpdated extends GalleryEvent {
  final List<Photo> photos;
  const PhotosUpdated(this.photos);

  @override
  List<Object?> get props => [photos];
}

class SyncProgressUpdated extends GalleryEvent {
  final int count;
  const SyncProgressUpdated(this.count);

  @override
  List<Object?> get props => [count];
}

class SearchGallery extends GalleryEvent {
  final String query;
  const SearchGallery(this.query);

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

class ToggleFavoriteFilter extends GalleryEvent {}

class SyncWithKDrive extends GalleryEvent {}
