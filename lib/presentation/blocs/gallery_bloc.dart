import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:k_photo/core/database/app_database.dart';
import 'package:k_photo/core/network/auth_repository.dart';
import 'package:k_photo/core/network/sync_engine.dart';
import 'package:intl/intl.dart';

part 'gallery_event.dart';
part 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final AppDatabase db;
  final SyncEngine? syncEngine;
  StreamSubscription? _photosSubscription;
  Timer? _throttleTimer;

  GalleryBloc(this.db, {this.syncEngine}) 
      : super(const GalleryState()) {
    on<LoadGallery>(_onLoadGallery);
    on<SearchGallery>(_onSearchGallery);
    on<SyncWithKDrive>(_onSyncWithKDrive);
    on<PhotosUpdated>(_onPhotosUpdated);
    on<SyncProgressUpdated>(_onSyncProgressUpdated);
    on<ChangeViewMode>(_onChangeViewMode);
    on<ToggleFavoriteFilter>(_onToggleFavoriteFilter);
    on<TogglePhotoSelection>(_onTogglePhotoSelection);
    on<ClearSelection>(_onClearSelection);
    on<DeleteSelectedPhotos>(_onDeleteSelectedPhotos);

    _photosSubscription = db.watchAllPhotos().listen((photos) {
      if (state.searchQuery.isEmpty) {
        // Gebruik een timer die updates doorlaat, maar niet vaker dan elke 1.5 seconde tijdens sync
        if (_throttleTimer?.isActive ?? false) return;

        final duration = (state.status == GalleryStatus.syncing) 
            ? const Duration(milliseconds: 800)
            : const Duration(milliseconds: 200);

        _throttleTimer = Timer(duration, () {
          add(PhotosUpdated(photos));
        });
      }
    });
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
    final photos = newShowOnlyFavorites 
        ? state.photos.where((p) => p.isFavorite).toList()
        : await db.getAllPhotos();
        
    final grouped = _groupPhotos(photos, state.viewMode);
    emit(state.copyWith(showOnlyFavorites: newShowOnlyFavorites, photos: photos, groupedPhotos: grouped));
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

  void _onSyncProgressUpdated(SyncProgressUpdated event, Emitter<GalleryState> emit) {
    emit(state.copyWith(processedCount: event.count));
  }

  Future<void> _onLoadGallery(LoadGallery event, Emitter<GalleryState> emit) async {
    emit(state.copyWith(status: GalleryStatus.loading));
    try {
      final photos = await db.getAllPhotos();
      final grouped = _groupPhotos(photos, state.viewMode);
      emit(state.copyWith(status: GalleryStatus.success, photos: photos, groupedPhotos: grouped));
    } catch (_) {
      emit(state.copyWith(status: GalleryStatus.failure));
    }
  }

  Future<void> _onSearchGallery(SearchGallery event, Emitter<GalleryState> emit) async {
    emit(state.copyWith(status: GalleryStatus.loading, searchQuery: event.query));
    try {
      final photos = event.query.isEmpty 
          ? await db.getAllPhotos()
          : await db.searchPhotos(event.query);
      final grouped = _groupPhotos(photos, state.viewMode);
      emit(state.copyWith(status: GalleryStatus.success, photos: photos, groupedPhotos: grouped));
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
        // 1. Optioneel verwijderen van kDrive
        if (event.remoteToo && syncEngine != null) {
          await syncEngine!.apiService.deleteFile(photo.kdrivePath);
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
}
