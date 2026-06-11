part of 'gallery_bloc.dart';

enum GalleryStatus { initial, loading, success, failure, syncing, syncFinished }
enum GalleryViewMode { month, day, large }

class GalleryState extends Equatable {
  final GalleryStatus status;
  final GalleryViewMode viewMode;
  final List<Photo> photos;
  final Map<String, List<Photo>> groupedPhotos;
  final String searchQuery;
  final bool showOnlyFavorites;
  final int processedCount;

  const GalleryState({
    this.status = GalleryStatus.initial,
    this.viewMode = GalleryViewMode.month,
    this.photos = const [],
    this.groupedPhotos = const {},
    this.searchQuery = '',
    this.showOnlyFavorites = false,
    this.processedCount = 0,
  });

  GalleryState copyWith({
    GalleryStatus? status,
    GalleryViewMode? viewMode,
    List<Photo>? photos,
    Map<String, List<Photo>>? groupedPhotos,
    String? searchQuery,
    bool? showOnlyFavorites,
    int? processedCount,
  }) {
    return GalleryState(
      status: status ?? this.status,
      viewMode: viewMode ?? this.viewMode,
      photos: photos ?? this.photos,
      groupedPhotos: groupedPhotos ?? this.groupedPhotos,
      searchQuery: searchQuery ?? this.searchQuery,
      showOnlyFavorites: showOnlyFavorites ?? this.showOnlyFavorites,
      processedCount: processedCount ?? this.processedCount,
    );
  }

  @override
  List<Object?> get props => [status, viewMode, photos, groupedPhotos, searchQuery, showOnlyFavorites, processedCount];
}
