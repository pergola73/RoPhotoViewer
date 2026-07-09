import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kphoto/core/database/app_database.dart';
import 'package:kphoto/core/network/auth_repository.dart';
import 'package:kphoto/core/network/sync_engine.dart';
import 'package:kphoto/core/services/ai_tagging_service.dart';
import 'package:intl/intl.dart';

part 'gallery_event.dart';
part 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final AppDatabase db;
  final SyncEngine? syncEngine;
  StreamSubscription? _photosSubscription;
  Timer? _throttleTimer;
  static const int _pageSize = 200;

  GalleryBloc(this.db, {this.syncEngine}) 
      : super(const GalleryState()) {
    on<LoadGallery>(_onLoadGallery);
    on<LoadMorePhotos>(_onLoadMorePhotos);
    on<SearchGallery>(_onSearchGallery);
    on<SyncWithKDrive>(_onSyncWithKDrive);
    on<PhotosUpdated>(_onPhotosUpdated);
    on<SyncProgressUpdated>(_onSyncProgressUpdated);
    on<ChangeViewMode>(_onChangeViewMode);
    on<ToggleFavoriteFilter>(_onToggleFavoriteFilter);
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
    on<StartAiScan>(_onStartAiScan);
    on<AiScanProgressUpdated>(_onAiScanProgressUpdated);
    on<AiScanFinished>(_onAiScanFinished);

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

  void _onSyncProgressUpdated(SyncProgressUpdated event, Emitter<GalleryState> emit) {
    emit(state.copyWith(processedCount: event.count));
  }

  Future<void> _onLoadGallery(LoadGallery event, Emitter<GalleryState> emit) async {
    emit(state.copyWith(status: GalleryStatus.loading, photos: [], hasReachedMax: false));
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
        // Voor zoekopdrachten laden we momenteel de hele match set, 
        // maar beperken we het resultaat in de DB query als dat nodig is.
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

  Future<void> _onSyncWithKDrive(SyncWithKDrive event, Emitter<GalleryState> emit) async {
    final engine = syncEngine;
    if (engine == null) return;
    
    emit(state.copyWith(status: GalleryStatus.syncing, processedCount: 0));

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

    // 2. Map ID's ophalen
    List<String> folderIds = await authRepo.getFolderIds();
    
    if (folderIds.isEmpty) {
      debugPrint('GalleryBloc: Geen mappen lokaal gevonden, check Firestore...');
      // Geef Firestore even de tijd om de data te synchroniseren (bijv. na verse login)
      await Future.delayed(const Duration(seconds: 3));
      folderIds = await authRepo.getFolderIds();
      
      // Als we na de wachtperiode nog steeds geen mappen hebben, maar wel token/driveId, 
      // probeer dan nogmaals de API te initialiseren voor de zekerheid
      if (folderIds.isNotEmpty && !engine.apiService.isInitialized) {
        final creds = await authRepo.getCredentials();
        if (creds['token'] != null && creds['driveId'] != null) {
          await engine.apiService.initialize(creds['token']!, creds['driveId']!);
        }
      }
    }
    
    if (folderIds.isEmpty) {
      debugPrint('GalleryBloc: Nog steeds geen mappen gevonden. Controleer instellingen.');
      emit(state.copyWith(status: GalleryStatus.success));
      return;
    }
    
    if (!engine.apiService.isInitialized) {
      debugPrint('GalleryBloc: API is niet geinitialiseerd. Sync afgebroken.');
      emit(state.copyWith(status: GalleryStatus.failure));
      return;
    }
    
    try {
      int total = 0;
      for (var folderId in folderIds) {
        debugPrint('GalleryBloc: Starten sync voor map ID: $folderId');
        await engine.sync(folderId, onProgress: (count) {
          total += count;
          if (!emit.isDone) {
            add(SyncProgressUpdated(total));
          }
        });
      }
      emit(state.copyWith(status: GalleryStatus.syncFinished));
      
      // Herlaad de eerste pagina na een sync om nieuwe foto's te tonen
      add(LoadGallery());
      
      // We starten de AI scan niet meer automatisch hier om interferentie te voorkomen.
      // De gebruiker kan dit nu handmatig doen in de instellingen voor meer controle.

    } catch (e) {
      debugPrint('GalleryBloc: Sync fout: $e');
      emit(state.copyWith(status: GalleryStatus.failure));
    } finally {
      if (!emit.isDone) {
        emit(state.copyWith(status: GalleryStatus.success));
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

  void _onAiScanProgressUpdated(AiScanProgressUpdated event, Emitter<GalleryState> emit) {
    emit(state.copyWith(aiScanCurrent: event.current, aiScanTotal: event.total));
  }

  void _onAiScanFinished(AiScanFinished event, Emitter<GalleryState> emit) {
    emit(state.copyWith(isAiScanning: false));
  }

  Future<void> _onStartAiScan(StartAiScan event, Emitter<GalleryState> emit) async {
    if (state.isAiScanning) return;
    
    emit(state.copyWith(isAiScanning: true, aiScanCurrent: 0, aiScanTotal: 0));
    
    final api = syncEngine?.apiService;
    final aiService = AITaggingService(db, api);
    
    // Start de scan op de achtergrond. Omdat we in een Bloc zitten, 
    // gebruiken we geen 'await' om de UI niet te blokkeren voor andere events.
    unawaited(aiService.processPendingPhotos(
      forceAll: event.forceAll,
      onProgress: (current, total) {
        add(AiScanProgressUpdated(current, total));
      },
    ).then((_) => add(AiScanFinished())));
  }
}
