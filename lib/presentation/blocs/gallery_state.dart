part of 'gallery_bloc.dart';

enum GalleryStatus { initial, loading, success, failure, syncing, syncFinished, initialSync }
enum GalleryViewMode { month, day, large }

class GalleryState extends Equatable {
  final GalleryStatus status;
  final SyncPhase syncPhase;
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
  final bool isIndexing;
  final int indexingCurrent;
  final int indexingTotal;
  final bool isFirstSyncComplete;
  final bool isSyncing; 
  final bool isManualSync;

  final List<dynamic> trashItems;
  final Set<String> selectedTrashIds;
  final bool hasReachedMax;
  final int totalPhotoCount;
  final String? estimatedTimeRemaining;

  const GalleryState({
    this.status = GalleryStatus.initial,
    this.syncPhase = SyncPhase.idle,
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
    this.isIndexing = false,
    this.indexingCurrent = 0,
    this.indexingTotal = 0,
    this.isFirstSyncComplete = false,
    this.isSyncing = false,
    this.isManualSync = false,
    this.trashItems = const [],
    this.selectedTrashIds = const {},
    this.hasReachedMax = false,
    this.totalPhotoCount = 0,
    this.estimatedTimeRemaining,
  });

  GalleryState copyWith({
    GalleryStatus? status,
    SyncPhase? syncPhase,
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
    bool? isIndexing,
    int? indexingCurrent,
    int? indexingTotal,
    bool? isFirstSyncComplete,
    bool? isSyncing,
    bool? isManualSync,
    List<dynamic>? trashItems,
    Set<String>? selectedTrashIds,
    bool? hasReachedMax,
    int? totalPhotoCount,
    String? estimatedTimeRemaining,
  }) {
    return GalleryState(
      status: status ?? this.status,
      syncPhase: syncPhase ?? this.syncPhase,
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
      isIndexing: isIndexing ?? this.isIndexing,
      indexingCurrent: indexingCurrent ?? this.indexingCurrent,
      indexingTotal: indexingTotal ?? this.indexingTotal,
      isFirstSyncComplete: isFirstSyncComplete ?? this.isFirstSyncComplete,
      isSyncing: isSyncing ?? this.isSyncing,
      isManualSync: isManualSync ?? this.isManualSync,
      trashItems: trashItems ?? this.trashItems,
      selectedTrashIds: selectedTrashIds ?? this.selectedTrashIds,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalPhotoCount: totalPhotoCount ?? this.totalPhotoCount,
      estimatedTimeRemaining: estimatedTimeRemaining ?? this.estimatedTimeRemaining,
    );
  }

  @override
  List<Object?> get props => [
    status, 
    syncPhase,
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
    isIndexing,
    indexingCurrent,
    indexingTotal,
    isFirstSyncComplete,
    isSyncing,
    isManualSync,
    trashItems,
    selectedTrashIds,
    hasReachedMax,
    totalPhotoCount,
    estimatedTimeRemaining,
  ];
}
