import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kphoto/core/database/app_database.dart';
import 'package:kphoto/core/network/auth_repository.dart';
import 'package:kphoto/core/network/sync_engine.dart';
import 'package:kphoto/core/services/ai_tagging_service.dart';
import 'package:kphoto/core/services/vector_search_service.dart';
import 'package:kphoto/core/services/media_processor_service.dart';
import 'package:kphoto/core/services/image_embedding_service.dart';
import 'package:kphoto/core/database/asset_entity.dart';
import 'package:kphoto/core/models/sync_phase.dart';
import 'package:intl/intl.dart';

part 'gallery_event.dart';
part 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final AppDatabase db;
  final SyncEngine? syncEngine;
  final VectorSearchService? vectorSearch;
  final MediaProcessorService? mediaProcessor;
  
  StreamSubscription? _photosSubscription;
  Timer? _throttleTimer;
  static const int _pageSize = 200;

  GalleryBloc(this.db, {
    this.syncEngine,
    this.vectorSearch,
    this.mediaProcessor,
  }) : super(const GalleryState()) {
    on<LoadGallery>(_onLoadGallery);
    on<LoadMorePhotos>(_onLoadMorePhotos);
    on<SearchGallery>(_onSearchGallery);
    on<SemanticSearch>(_onSemanticSearch);
    on<SyncWithKDrive>(_onSyncWithKDrive);
    on<PhotosUpdated>(_onPhotosUpdated);
    on<SyncProgressUpdated>(_onSyncProgressUpdated);
    on<ChangeViewMode>(_onChangeViewMode);
    on<ToggleFavoriteFilter>(_onToggleFavoriteFilter);
    on<ToggleSelectedPhotosFavorite>(_onToggleSelectedPhotosFavorite);
    on<TogglePhotoSelection>(_onTogglePhotoSelection);
    on<SelectAll>(_onSelectAll);
    on<SelectSection>(_onSelectSection);
    on<ClearSelection>(_onClearSelection);
    on<DeleteSelectedPhotos>(_onDeleteSelectedPhotos);
    on<LoadTrash>(_onLoadTrash);
    on<RestoreSelectedFromTrash>(_onRestoreSelectedFromTrash);
    on<ToggleTrashSelection>(_onToggleTrashSelection);
    on<ClearTrashSelection>(_onClearTrashSelection);
    on<DeleteSelectedFromTrash>(_onDeleteSelectedFromTrash);
    on<EmptyTrash>(_onEmptyTrash);
    on<UpdatePhotoMetadata>(_onUpdatePhotoMetadata);
    on<StartAiScan>(_onStartAiScan);
    on<AiScanProgressUpdated>(_onAiScanProgressUpdated);
    on<AiScanFinished>(_onAiScanFinished);
    on<IndexingProgressUpdated>(_onIndexingProgressUpdated);
    on<IndexingFinished>(_onIndexingFinished);

    // We stoppen met het constant monitoren van de gehele tabel bij 30.000 items.
    // In plaats daarvan laden we expliciet bij acties.
  }

  @override
  Future<void> close() {
    _photosSubscription?.cancel();
    _throttleTimer?.cancel();
    return super.close();
  }

  Map<String, List<Photo>> _groupPhotos(List<Photo> photos, GalleryViewMode mode) {
    final Map<String, List<Photo>> groups = {};
    for (var photo in photos) {
      String key;
      if (mode == GalleryViewMode.month) {
        String formatted = DateFormat('MMMM yyyy', 'nl_NL').format(photo.dateTaken);
        key = formatted[0].toUpperCase() + formatted.substring(1);
      } else if (mode == GalleryViewMode.day) {
        key = DateFormat('EEEE d MMMM yyyy', 'nl_NL').format(photo.dateTaken);
      } else {
        key = 'Alle foto\'s';
      }
      
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(photo);
    }
    return groups;
  }

  void _onPhotosUpdated(PhotosUpdated event, Emitter<GalleryState> emit) {
    var photos = event.photos;
    if (state.showOnlyFavorites) {
      photos = photos.where((p) => p.isFavorite).toList();
    }
    final grouped = _groupPhotos(photos, state.viewMode);
    final newStatus = (state.status == GalleryStatus.syncing) ? GalleryStatus.syncing : GalleryStatus.success;
    emit(state.copyWith(
      status: newStatus, 
      photos: photos,
      groupedPhotos: grouped,
    ));
  }

  void _onChangeViewMode(ChangeViewMode event, Emitter<GalleryState> emit) {
    final grouped = _groupPhotos(state.photos, event.mode);
    emit(state.copyWith(viewMode: event.mode, groupedPhotos: grouped));
  }

  void _onToggleFavoriteFilter(ToggleFavoriteFilter event, Emitter<GalleryState> emit) async {
    final newShowOnlyFavorites = !state.showOnlyFavorites;
    emit(state.copyWith(showOnlyFavorites: newShowOnlyFavorites));
    add(LoadGallery());
  }

  void _onToggleSelectedPhotosFavorite(ToggleSelectedPhotosFavorite event, Emitter<GalleryState> emit) async {
    if (state.selectedPhotoIds.isEmpty) return;
    
    // We kijken naar de eerste geselecteerde foto om te bepalen of we alles AAN of UIT zetten
    final firstPhoto = state.photos.firstWhere((p) => state.selectedPhotoIds.contains(p.id));
    final bool newState = !firstPhoto.isFavorite;

    for (var id in state.selectedPhotoIds) {
      await db.toggleFavorite(id, newState);
    }

    emit(state.copyWith(selectedPhotoIds: {})); // Wis selectie na actie
    add(LoadGallery()); // Ververs UI
  }

  void _onTogglePhotoSelection(TogglePhotoSelection event, Emitter<GalleryState> emit) {
    final currentSelection = Set<int>.from(state.selectedPhotoIds);
    if (currentSelection.contains(event.photoId)) {
      currentSelection.remove(event.photoId);
    } else {
      currentSelection.add(event.photoId);
    }
    emit(state.copyWith(selectedPhotoIds: currentSelection));
  }

  void _onClearSelection(ClearSelection event, Emitter<GalleryState> emit) {
    emit(state.copyWith(selectedPhotoIds: {}));
  }

  void _onSelectAll(SelectAll event, Emitter<GalleryState> emit) {
    final allIds = state.photos.map((p) => p.id).toSet();
    emit(state.copyWith(selectedPhotoIds: allIds));
  }

  void _onSelectSection(SelectSection event, Emitter<GalleryState> emit) {
    final currentSelection = Set<int>.from(state.selectedPhotoIds);
    final sectionIds = event.photoIds;
    
    // Als de hele sectie al geselecteerd is, deselecteer dan alles in die sectie
    bool allSelected = true;
    for (var id in sectionIds) {
      if (!currentSelection.contains(id)) {
        allSelected = false;
        break;
      }
    }

    if (allSelected) {
      for (var id in sectionIds) {
        currentSelection.remove(id);
      }
    } else {
      for (var id in sectionIds) {
        currentSelection.add(id);
      }
    }
    
    emit(state.copyWith(selectedPhotoIds: currentSelection));
  }

  DateTime? _syncStartTime;
  DateTime? _lastAutoSync;
  int? _initialPendingCount;

  void _onSyncProgressUpdated(SyncProgressUpdated event, Emitter<GalleryState> emit) async {
    final count = await db.getTotalPhotoCount(onlyFavorites: state.showOnlyFavorites);
    
    String? timeLeft;
    final int estimatedTotal = state.totalPhotoCount > 0 ? state.totalPhotoCount : 30000;

    if (_syncStartTime != null && event.count > 50) {
      final elapsed = DateTime.now().difference(_syncStartTime!);
      final itemsLeft = estimatedTotal - event.count;
      
      if (itemsLeft > 0) {
        final msPerItem = elapsed.inMilliseconds / event.count;
        final secondsLeft = (itemsLeft * msPerItem) / 1000;
        if (secondsLeft < 3600) {
          timeLeft = '${(secondsLeft / 60).ceil()} min resteert';
        }
      }
    }

    emit(state.copyWith(
      processedCount: event.count, 
      totalPhotoCount: count,
      estimatedTimeRemaining: timeLeft,
      syncPhase: event.phase ?? state.syncPhase,
      isSyncing: true,
    ));

    final int reloadFrequency = event.count < 1000 ? 50 : 500;
    
    if (event.count % reloadFrequency == 0) {
      final photos = await db.getPhotosPaged(_pageSize, 0, onlyFavorites: state.showOnlyFavorites);
      final grouped = _groupPhotos(photos, state.viewMode);
      emit(state.copyWith(photos: photos, groupedPhotos: grouped));
    }
  }

  Future<void> _onLoadGallery(LoadGallery event, Emitter<GalleryState> emit) async {
    // Wis de lijst niet als we al foto's hebben (voorkomt flikkering bij refresh)
    emit(state.copyWith(status: GalleryStatus.loading, hasReachedMax: false));
    try {
      final totalCount = await db.getTotalPhotoCount(onlyFavorites: state.showOnlyFavorites);
      final photos = await db.getPhotosPaged(_pageSize, 0, onlyFavorites: state.showOnlyFavorites);
      final grouped = _groupPhotos(photos, state.viewMode);
      emit(state.copyWith(
        status: GalleryStatus.success, 
        photos: photos, 
        groupedPhotos: grouped,
        hasReachedMax: photos.length < _pageSize,
        totalPhotoCount: totalCount,
      ));
    } catch (_) {
      emit(state.copyWith(status: GalleryStatus.failure));
    }
  }

  Future<void> _onLoadMorePhotos(LoadMorePhotos event, Emitter<GalleryState> emit) async {
    if (state.hasReachedMax || state.status == GalleryStatus.loading) return;

    try {
      final photos = await db.getPhotosPaged(_pageSize, state.photos.length, onlyFavorites: state.showOnlyFavorites);
      if (photos.isEmpty) {
        emit(state.copyWith(hasReachedMax: true));
      } else {
        final allPhotos = List<Photo>.from(state.photos)..addAll(photos);
        final grouped = _groupPhotos(allPhotos, state.viewMode);
        emit(state.copyWith(
          status: GalleryStatus.success,
          photos: allPhotos,
          groupedPhotos: grouped,
          hasReachedMax: photos.length < _pageSize,
        ));
      }
    } catch (_) {
      emit(state.copyWith(status: GalleryStatus.failure));
    }
  }

  Future<void> _onSearchGallery(SearchGallery event, Emitter<GalleryState> emit) async {
    emit(state.copyWith(status: GalleryStatus.loading, searchQuery: event.query));
    try {
      List<Photo> photos;
      if (event.query.isEmpty) {
        photos = await db.getPhotosPaged(_pageSize, 0);
      } else {
        // Keyword-based search in Drift
        photos = await db.searchPhotos(event.query);
      }
      final grouped = _groupPhotos(photos, state.viewMode);
      emit(state.copyWith(
        status: GalleryStatus.success, 
        photos: photos, 
        groupedPhotos: grouped,
        hasReachedMax: event.query.isNotEmpty || photos.length < _pageSize,
      ));
    } catch (_) {
      emit(state.copyWith(status: GalleryStatus.failure));
    }
  }

  Future<void> _onSemanticSearch(SemanticSearch event, Emitter<GalleryState> emit) async {
    // Voorlopig uitgeschakeld tot CLIP modellen aanwezig zijn
    emit(state.copyWith(status: GalleryStatus.loading, searchQuery: event.query));
    add(SearchGallery(event.query));
  }

  Future<void> _onSyncWithKDrive(SyncWithKDrive event, Emitter<GalleryState> emit) async {
    final engine = syncEngine;
    if (engine == null) return;
    
    final now = DateTime.now();
    if (!event.isManual && _lastAutoSync != null && now.difference(_lastAutoSync!).inMinutes < 30) {
      debugPrint('GalleryBloc: Auto-sync overgeslagen (cooldown actief)');
      return;
    }
    _lastAutoSync = now;
    
    final currentPhotoCount = await db.getTotalPhotoCount();
    final isInitial = currentPhotoCount == 0;

    _syncStartTime = DateTime.now();
    
    if (isInitial) {
      emit(state.copyWith(status: GalleryStatus.initialSync, syncPhase: SyncPhase.scanning, processedCount: 0, isSyncing: true, isManualSync: true));
    } else {
      emit(state.copyWith(status: GalleryStatus.syncing, syncPhase: SyncPhase.scanning, processedCount: 0, isSyncing: true, isManualSync: event.isManual));
    }

    final authRepo = AuthRepository();
    
    // 1. Zorg dat de API geinitialiseerd is (belangrijk bij schone installatie)
    if (!engine.apiService.isInitialized) {
      final creds = await authRepo.getCredentials();
      if (creds['token'] != null && creds['driveId'] != null) {
        try {
          debugPrint('GalleryBloc: API initialiseren met gevonden credentials...');
          await engine.apiService.initialize(creds['token']!, creds['driveId']!);
        } catch (e) {
          debugPrint('GalleryBloc: API initialisatie mislukt: $e');
        }
      }
    }

    // 2. Map ID's ophalen met versterkte detectie
    List<String> folderIds = await authRepo.getFolderIds();
    debugPrint('GalleryBloc: Initiële mappen-check: $folderIds');
    
    if (folderIds.isEmpty) {
      // Laatste redding: probeer direct uit storage te lezen
      final storage = FlutterSecureStorage();
      final rawIds = await storage.read(key: 'kdrive_folder_ids');
      if (rawIds != null && rawIds.isNotEmpty) {
        folderIds = rawIds.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        debugPrint('GalleryBloc: Mappen hersteld via DirectStorage: $folderIds');
      }
    }
    
    if (folderIds.isEmpty) {
      debugPrint('GalleryBloc: FOUT - Echt geen mappen gevonden na alle pogingen.');
      emit(state.copyWith(status: GalleryStatus.success));
      return;
    }
    
    if (!engine.apiService.isInitialized) {
      debugPrint('GalleryBloc: API is niet geinitialiseerd. Sync afgebroken.');
      emit(state.copyWith(status: GalleryStatus.failure));
      return;
    }
    
    try {
      debugPrint('GalleryBloc: Starten sync voor mappen: $folderIds');
      await engine.sync(
        folderIds, 
        isInitialSync: isInitial,
        onProgress: (count, phase) {
          if (!emit.isDone) {
            add(SyncProgressUpdated(count, phase: phase));
          }
        },
        onIndexingProgress: (current, total) {
          if (!emit.isDone) {
            add(IndexingProgressUpdated(current, total));
          }
        },
      );
      
      if (isInitial) {
        emit(state.copyWith(isFirstSyncComplete: true));
      }

      emit(state.copyWith(status: GalleryStatus.syncFinished, syncPhase: SyncPhase.idle, isSyncing: false));
      
      // Belangrijk: AI scan ALLEEN handmatig of als de sync volledig IDLE is.
      // We triggeren hem hier nu NIET meer automatisch om chaos te voorkomen.
      add(LoadGallery());

    } catch (e) {
      debugPrint('GalleryBloc: Sync fout: $e');
      if (!emit.isDone) {
        emit(state.copyWith(status: GalleryStatus.failure));
      }
    }
  }

  Future<void> _onDeleteSelectedPhotos(DeleteSelectedPhotos event, Emitter<GalleryState> emit) async {
    if (state.selectedPhotoIds.isEmpty) return;

    final photosToDelete = state.photos.where((p) => state.selectedPhotoIds.contains(p.id)).toList();
    
    emit(state.copyWith(status: GalleryStatus.loading));
    
    try {
      for (var photo in photosToDelete) {
        // 1. Optioneel verwijderen van kDrive (naar prullenbak of definitief)
        if (event.remoteToo && syncEngine != null) {
          if (event.permanent) {
            await syncEngine!.apiService.deleteFilePermanent(photo.kdrivePath);
          } else {
            await syncEngine!.apiService.moveToTrash(photo.kdrivePath);
          }
        }
        
        // 2. Altijd verwijderen uit lokale database en bestandssysteem
        await db.deletePhoto(photo);
      }
      
      emit(state.copyWith(status: GalleryStatus.success, selectedPhotoIds: {}));
    } catch (e) {
      debugPrint('GalleryBloc: Fout bij verwijderen: $e');
      emit(state.copyWith(status: GalleryStatus.failure));
    }
  }

  void _onToggleTrashSelection(ToggleTrashSelection event, Emitter<GalleryState> emit) {
    final currentSelection = Set<String>.from(state.selectedTrashIds);
    if (currentSelection.contains(event.itemId)) {
      currentSelection.remove(event.itemId);
    } else {
      currentSelection.add(event.itemId);
    }
    emit(state.copyWith(selectedTrashIds: currentSelection));
  }

  void _onClearTrashSelection(ClearTrashSelection event, Emitter<GalleryState> emit) {
    emit(state.copyWith(selectedTrashIds: {}));
  }

  Future<void> _onLoadTrash(LoadTrash event, Emitter<GalleryState> emit) async {
    if (syncEngine == null) return;
    emit(state.copyWith(status: GalleryStatus.loading));
    try {
      final trash = await syncEngine!.apiService.getTrash();
      emit(state.copyWith(status: GalleryStatus.success, trashItems: trash));
    } catch (_) {
      emit(state.copyWith(status: GalleryStatus.failure));
    }
  }

  Future<void> _onRestoreSelectedFromTrash(RestoreSelectedFromTrash event, Emitter<GalleryState> emit) async {
    if (syncEngine == null || state.selectedTrashIds.isEmpty) return;
    
    emit(state.copyWith(status: GalleryStatus.loading));
    try {
      for (var id in state.selectedTrashIds) {
        await syncEngine!.apiService.restoreFile(id);
      }
      final trash = await syncEngine!.apiService.getTrash();
      emit(state.copyWith(status: GalleryStatus.success, trashItems: trash, selectedTrashIds: {}));
      add(SyncWithKDrive());
    } catch (e) {
      debugPrint('GalleryBloc: Fout bij herstellen uit prullenbak: $e');
      emit(state.copyWith(status: GalleryStatus.failure));
    }
  }

  Future<void> _onDeleteSelectedFromTrash(DeleteSelectedFromTrash event, Emitter<GalleryState> emit) async {
    if (syncEngine == null || state.selectedTrashIds.isEmpty) return;
    
    emit(state.copyWith(status: GalleryStatus.loading));
    try {
      for (var id in state.selectedTrashIds) {
        if (event.permanent) {
          await syncEngine!.apiService.deleteFilePermanent(id);
        } else {
          await syncEngine!.apiService.moveToTrash(id);
        }
      }
      final trash = await syncEngine!.apiService.getTrash();
      emit(state.copyWith(status: GalleryStatus.success, trashItems: trash, selectedTrashIds: {}));
    } catch (e) {
      debugPrint('GalleryBloc: Fout bij verwijderen uit prullenbak: $e');
      emit(state.copyWith(status: GalleryStatus.failure));
    }
  }

  Future<void> _onEmptyTrash(EmptyTrash event, Emitter<GalleryState> emit) async {
    if (syncEngine == null) return;
    
    emit(state.copyWith(status: GalleryStatus.loading));
    try {
      await syncEngine!.apiService.emptyTrash();
      emit(state.copyWith(status: GalleryStatus.success, trashItems: [], selectedTrashIds: {}));
    } catch (e) {
      debugPrint('GalleryBloc: Fout bij legen prullenbak: $e');
      emit(state.copyWith(status: GalleryStatus.failure));
    }
  }

  Future<void> _onUpdatePhotoMetadata(UpdatePhotoMetadata event, Emitter<GalleryState> emit) async {
    await db.updatePhotoMetadata(event.photoId, date: event.date, keywords: event.keywords);
    // Ververs de gallerij zodat de foto op de nieuwe plek staat
    add(LoadGallery());
  }

  void _onAiScanProgressUpdated(AiScanProgressUpdated event, Emitter<GalleryState> emit) {
    emit(state.copyWith(aiScanCurrent: event.current, aiScanTotal: event.total));
  }

  void _onAiScanFinished(AiScanFinished event, Emitter<GalleryState> emit) {
    emit(state.copyWith(isAiScanning: false));
  }

  void _onIndexingProgressUpdated(IndexingProgressUpdated event, Emitter<GalleryState> emit) {
    emit(state.copyWith(
      isIndexing: true, 
      indexingCurrent: event.current, 
      indexingTotal: event.total
    ));
  }

  void _onIndexingFinished(IndexingFinished event, Emitter<GalleryState> emit) {
    emit(state.copyWith(isIndexing: false));
  }

  Future<void> _onStartAiScan(StartAiScan event, Emitter<GalleryState> emit) async {
    if (state.isAiScanning) return;
    
    emit(state.copyWith(isAiScanning: true, indexingCurrent: 0, indexingTotal: 0));
    
    if (mediaProcessor != null) {
      final photos = await db.getAllPhotos();
      final paths = photos
          .where((p) => p.localThumbnailPath != null && File(p.localThumbnailPath!).existsSync())
          .map((p) => p.localThumbnailPath!)
          .toList();
          
      if (paths.isNotEmpty) {
        unawaited(mediaProcessor!.processNewFiles(
          paths, 
          onProgress: (current, total) => add(IndexingProgressUpdated(current, total))
        ).then((_) => add(IndexingFinished())));
      } else {
        emit(state.copyWith(isAiScanning: false));
      }
    }
  }
}
