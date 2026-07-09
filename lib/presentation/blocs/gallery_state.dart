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
  final Set<int> selectedPhotoIds;
  final int processedCount;
  final bool isAiScanning;
  final int aiScanCurrent;
  final int aiScanTotal;

  final List<dynamic> trashItems;
  final Set<String> selectedTrashIds;

  const GalleryState({
    this.status = GalleryStatus.initial,
    this.viewMode = GalleryViewMode.month,
    this.photos = const [],
    this.groupedPhotos = const {},
    this.searchQuery = '',
    this.showOnlyFavorites = false,
    this.selectedPhotoIds = const {},
    this.processedCount = 0,
    this.isAiScanning = false,
    this.aiScanCurrent = 0,
    this.aiScanTotal = 0,
    this.trashItems = const [],
    this.selectedTrashIds = const {},
  });

  GalleryState copyWith({
    GalleryStatus? status,
    GalleryViewMode? viewMode,
    List<Photo>? photos,
    Map<String, List<Photo>>? groupedPhotos,
    String? searchQuery,
    bool? showOnlyFavorites,
    Set<int>? selectedPhotoIds,
    int? processedCount,
    bool? isAiScanning,
    int? aiScanCurrent,
    int? aiScanTotal,
    List<dynamic>? trashItems,
    Set<String>? selectedTrashIds,
  }) {
    return GalleryState(
      status: status ?? this.status,
      viewMode: viewMode ?? this.viewMode,
      photos: photos ?? this.photos,
      groupedPhotos: groupedPhotos ?? this.groupedPhotos,
      searchQuery: searchQuery ?? this.searchQuery,
      showOnlyFavorites: showOnlyFavorites ?? this.showOnlyFavorites,
      selectedPhotoIds: selectedPhotoIds ?? this.selectedPhotoIds,
      processedCount: processedCount ?? this.processedCount,
      isAiScanning: isAiScanning ?? this.isAiScanning,
      aiScanCurrent: aiScanCurrent ?? this.aiScanCurrent,
      aiScanTotal: aiScanTotal ?? this.aiScanTotal,
      trashItems: trashItems ?? this.trashItems,
      selectedTrashIds: selectedTrashIds ?? this.selectedTrashIds,
    );
  }

  @override
  List<Object?> get props => [
    status, 
    viewMode, 
    photos, 
    groupedPhotos, 
    searchQuery, 
    showOnlyFavorites, 
    selectedPhotoIds, 
    processedCount,
    isAiScanning,
    aiScanCurrent,
    aiScanTotal,
    trashItems,
    selectedTrashIds,
  ];
}
