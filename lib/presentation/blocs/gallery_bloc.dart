import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ro_photo_viewer/core/database/app_database.dart';
import 'package:ro_photo_viewer/core/network/sync_engine.dart';
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
        key = DateFormat('MMMM yyyy', 'nl_NL').format(photo.dateTaken);
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
    
    final creds = await AuthRepository().getCredentials();
    final folderId = creds['folderId'];
    if (folderId == null) return;

    emit(state.copyWith(status: GalleryStatus.syncing, processedCount: 0));
    await engine.sync(folderId, onProgress: (count) {
      if (!emit.isDone) {
        add(SyncProgressUpdated(count));
      }
    });
    
    emit(state.copyWith(status: GalleryStatus.syncFinished));
    emit(state.copyWith(status: GalleryStatus.success));
  }
}
