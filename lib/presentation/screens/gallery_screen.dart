import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:k_photo/core/database/app_database.dart';

import 'package:k_photo/presentation/blocs/gallery_bloc.dart';

import 'package:k_photo/presentation/screens/photo_viewer_screen.dart';
import 'package:k_photo/presentation/screens/settings_screen.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    // Start automatische sync op de achtergrond bij openen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryBloc>().add(SyncWithKDrive());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        bottomNavigationBar: Material(
          elevation: 8,
          color: Theme.of(context).cardColor,
          child: SafeArea(
            child: TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(icon: Icon(Icons.photo_library), text: 'Foto\'s'),
                Tab(icon: Icon(Icons.collections), text: 'Albums'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildPhotosTab(context),
            _buildAlbumsTab(context),
          ],
        ),
        floatingActionButton: BlocBuilder<GalleryBloc, GalleryState>(
          builder: (context, state) {
            if (state.selectedPhotoIds.isNotEmpty) return const SizedBox.shrink();
            return FloatingActionButton(
              onPressed: () => context.read<GalleryBloc>().add(SyncWithKDrive()),
              child: state.status == GalleryStatus.syncing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhotosTab(BuildContext context) {
    return BlocBuilder<GalleryBloc, GalleryState>(
      builder: (context, state) {
        final sortedSections = state.groupedPhotos.keys.toList();
        final isSelectionMode = state.selectedPhotoIds.isNotEmpty;

        int crossAxisCount = 4;
        if (state.viewMode == GalleryViewMode.large) crossAxisCount = 1;
        if (state.viewMode == GalleryViewMode.day) crossAxisCount = 2;
        if (state.viewMode == GalleryViewMode.month) crossAxisCount = 4;

        return Scaffold(
          appBar: isSelectionMode 
            ? _buildSelectionAppBar(context, state)
            : _buildNormalAppBar(context, state),
          body: GestureDetector(
            onScaleStart: (_) => _baseScale = 1.0,
            onScaleUpdate: (details) {
              final scale = details.scale;
              if ((scale - _baseScale).abs() > 0.3) {
                if (scale > 1.3) {
                  // Zoom in -> Minder kolommen (Grotere foto's)
                  if (state.viewMode == GalleryViewMode.month) {
                    context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.day));
                    _baseScale = scale;
                  } else if (state.viewMode == GalleryViewMode.day) {
                    context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.large));
                    _baseScale = scale;
                  }
                } else if (scale < 0.7) {
                  // Zoom uit -> Meer kolommen (Kleinere foto's)
                  if (state.viewMode == GalleryViewMode.large) {
                    context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.day));
                    _baseScale = scale;
                  } else if (state.viewMode == GalleryViewMode.day) {
                    context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.month));
                    _baseScale = scale;
                  }
                }
              }
            },
            child: Scrollbar(
              controller: _scrollController,
              interactive: true,
              thickness: 8,
              radius: const Radius.circular(4),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  if (state.status == GalleryStatus.loading && state.photos.isEmpty)
                    const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                  
                  if (state.photos.isEmpty && state.status != GalleryStatus.loading && state.status != GalleryStatus.syncing)
                    const SliverFillRemaining(child: Center(child: Text('Geen foto\'s gevonden.'))),

                  for (var section in sortedSections)
                    SliverStickyHeader(
                      header: Container(
                        height: 50.0,
                        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          section,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      sliver: SliverGrid(
                        gridDelegate: crossAxisCount > 1 
                          ? SliverQuiltedGridDelegate(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 1,
                              crossAxisSpacing: 1,
                              repeatPattern: QuiltedGridRepeatPattern.same,
                              pattern: [
                                const QuiltedGridTile(2, 2),
                                const QuiltedGridTile(1, 1),
                                const QuiltedGridTile(1, 1),
                                const QuiltedGridTile(1, 2),
                              ],
                            )
                          : const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              mainAxisSpacing: 1,
                              crossAxisSpacing: 1,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final photo = state.groupedPhotos[section]![index];
                            final isSelected = state.selectedPhotoIds.contains(photo.id);
                            
                            return GestureDetector(
                              key: ValueKey(photo.id),
                              onTap: () {
                                if (isSelectionMode) {
                                  context.read<GalleryBloc>().add(TogglePhotoSelection(photo.id));
                                } else {
                                  final fullIndex = state.photos.indexOf(photo);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PhotoViewerScreen(
                                        photos: state.photos,
                                        initialIndex: fullIndex >= 0 ? fullIndex : 0,
                                      ),
                                    ),
                                  );
                                }
                              },
                              onLongPress: () {
                                context.read<GalleryBloc>().add(TogglePhotoSelection(photo.id));
                              },
                              child: Hero(
                                tag: photo.id,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(
                                      color: Colors.grey[300],
                                      child: (photo.localThumbnailPath != null && File(photo.localThumbnailPath!).existsSync())
                                          ? Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                // 1. Basis thumbnail (snel geladen)
                                                Image.file(
                                                  File(photo.localThumbnailPath!),
                                                  fit: BoxFit.cover,
                                                  cacheWidth: crossAxisCount == 1 ? 800 : 400,
                                                  filterQuality: FilterQuality.low,
                                                ),
                                                // 2. High-res preview (indien aanwezig) voor de grote tegels
                                                if ((crossAxisCount <= 2) && photo.localHighResPath != null && File(photo.localHighResPath!).existsSync() && photo.mediaType == 'image')
                                                  Image.file(
                                                    File(photo.localHighResPath!),
                                                    fit: BoxFit.cover,
                                                    // Optimaliseer cacheWidth voor schermbreedte om geheugen te sparen
                                                    cacheWidth: crossAxisCount == 1 ? 1080 : 600,
                                                    filterQuality: FilterQuality.medium,
                                                  ),
                                                if (photo.mediaType == 'video')
                                                  const Positioned(
                                                    right: 8,
                                                    bottom: 8,
                                                    child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 24),
                                                  ),
                                              ],
                                            )
                                          : const Center(child: Icon(Icons.photo, color: Colors.white, size: 20)),
                                    ),
                                    if (isSelected)
                                      Container(
                                        color: Colors.white.withOpacity(0.3),
                                        child: const Center(
                                          child: Icon(Icons.check_circle, color: Colors.blue, size: 30),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: state.groupedPhotos[section]!.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildNormalAppBar(BuildContext context, GalleryState state) {
    return AppBar(
      title: _isSearching 
        ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Zoek op tag, locatie of naam...', border: InputBorder.none),
            onChanged: (query) => context.read<GalleryBloc>().add(SearchGallery(query)),
          )
        : const Text('K-Photo'),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              if (_isSearching) {
                _isSearching = false;
                _searchController.clear();
                context.read<GalleryBloc>().add(const SearchGallery(''));
              } else {
                _isSearching = true;
              }
            });
          },
        ),
        PopupMenuButton<GalleryViewMode>(
          icon: const Icon(Icons.grid_view),
          onSelected: (mode) => context.read<GalleryBloc>().add(ChangeViewMode(mode)),
          itemBuilder: (context) => [
            const PopupMenuItem(value: GalleryViewMode.large, child: Text('Heel ruim')),
            const PopupMenuItem(value: GalleryViewMode.day, child: Text('Dag')),
            const PopupMenuItem(value: GalleryViewMode.month, child: Text('Maand')),
          ],
        ),
        IconButton(
          icon: Icon(
            state.showOnlyFavorites ? Icons.star : Icons.star_border,
            color: state.showOnlyFavorites ? Colors.yellow : null,
          ),
          onPressed: () => context.read<GalleryBloc>().add(ToggleFavoriteFilter()),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
          },
        ),
      ],
    );
  }

  AppBar _buildSelectionAppBar(BuildContext context, GalleryState state) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.read<GalleryBloc>().add(ClearSelection()),
      ),
      title: Text('${state.selectedPhotoIds.length} geselecteerd'),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareSelected(state),
        ),
        IconButton(
          icon: const Icon(Icons.add_to_photos),
          onPressed: () => _addSelectedToAlbum(state),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteSelected(state),
        ),
      ],
    );
  }

  void _shareSelected(GalleryState state) async {
    final selectedPhotos = state.photos.where((p) => state.selectedPhotoIds.contains(p.id)).toList();
    final paths = selectedPhotos
        .map((p) => p.localHighResPath ?? p.localThumbnailPath)
        .whereType<String>()
        .where((path) => File(path).existsSync())
        .toList();

    if (paths.isNotEmpty) {
      await Share.shareXFiles(paths.map((p) => XFile(p)).toList());
    }
  }

  void _addSelectedToAlbum(GalleryState state) async {
    final db = context.read<GalleryBloc>().db;
    final albums = await db.getAllAlbums();
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Nieuw Album'),
              onTap: () {
                Navigator.pop(context);
                _createNewAlbumWithSelected(state);
              },
            ),
            const Divider(),
            ...albums.map((album) => ListTile(
              leading: const Icon(Icons.photo_album),
              title: Text(album.name),
              onTap: () async {
                for (var photoId in state.selectedPhotoIds) {
                  await db.addPhotoToAlbum(album.id, photoId);
                }
                if (mounted) {
                  Navigator.pop(context);
                  context.read<GalleryBloc>().add(ClearSelection());
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Toegevoegd aan ${album.name}')));
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _createNewAlbumWithSelected(GalleryState state) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuw Album'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Album naam'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Maken')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final db = context.read<GalleryBloc>().db;
      final albumId = await db.createAlbum(result, coverPhotoId: state.selectedPhotoIds.first);
      for (var photoId in state.selectedPhotoIds) {
        await db.addPhotoToAlbum(albumId, photoId);
      }
      if (mounted) {
        context.read<GalleryBloc>().add(ClearSelection());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Album "$result" gemaakt')));
      }
    }
  }

  void _deleteSelected(GalleryState state) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Foto\'s verwijderen'),
        content: Text('Wat wil je doen met deze ${state.selectedPhotoIds.length} foto\'s?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 1),
            child: const Text('Alleen lokaal', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 2),
            child: const Text('Overal (Lokaal & kDrive)', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == 1) {
      context.read<GalleryBloc>().add(const DeleteSelectedPhotos(remoteToo: false));
    } else if (result == 2) {
      context.read<GalleryBloc>().add(const DeleteSelectedPhotos(remoteToo: true));
    }
  }

  Widget _buildAlbumsTab(BuildContext context) {
    final db = context.read<GalleryBloc>().db;
    return StreamBuilder<List<Album>>(
      stream: db.watchAllAlbums(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final albums = snapshot.data!;
        
        if (albums.isEmpty) return const Center(child: Text('Nog geen albums gemaakt.'));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return FutureBuilder<List<Photo>>(
              future: db.getPhotosInAlbum(album.id),
              builder: (context, photoSnapshot) {
                final photos = photoSnapshot.data ?? [];
                String? coverPath;
                if (photos.isNotEmpty) {
                  coverPath = photos.first.localThumbnailPath;
                }

                return GestureDetector(
                  onTap: () => _openAlbum(context, album),
                  onLongPress: () => _showAlbumOptions(context, album),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            image: coverPath != null && File(coverPath).existsSync()
                              ? DecorationImage(image: FileImage(File(coverPath)), fit: BoxFit.cover)
                              : null,
                          ),
                          child: coverPath == null ? const Center(child: Icon(Icons.photo_album, size: 40, color: Colors.grey)) : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(album.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Text('${photos.length} foto\'s', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  void _showAlbumOptions(BuildContext context, Album album) {
    final db = context.read<GalleryBloc>().db;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Naam wijzigen'),
              onTap: () async {
                Navigator.pop(context);
                final controller = TextEditingController(text: album.name);
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Naam wijzigen'),
                    content: TextField(controller: controller, autofocus: true),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
                      TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Opslaan')),
                    ],
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  await db.updateAlbum(album.id, result, album.coverPhotoId);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Album verwijderen', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Verwijderen?'),
                    content: Text('Weet je zeker dat je album "${album.name}" wilt verwijderen? De foto\'s blijven bewaard.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuleren')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verwijderen', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await db.deleteAlbum(album.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openAlbum(BuildContext context, Album album) async {
    final db = context.read<GalleryBloc>().db;
    final photos = await db.getPhotosInAlbum(album.id);
    if (!context.mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(album.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addPhotosToExistingAlbum(context, album),
            ),
          ],
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(1),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1, mainAxisSpacing: 1),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PhotoViewerScreen(photos: photos, initialIndex: index),
                ));
              },
              onLongPress: () => _showAlbumPhotoOptions(context, album, photo),
              child: Image.file(File(photo.localThumbnailPath!), fit: BoxFit.cover),
            );
          },
        ),
      ),
    ));
  }

  void _showAlbumPhotoOptions(BuildContext context, Album album, Photo photo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
              title: const Text('Uit album verwijderen'),
              onTap: () async {
                await AppDatabase().removePhotoFromAlbum(album.id, photo.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context); // Close album detail and reopen to refresh (simple way)
                  _openAlbum(context, album);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addPhotosToExistingAlbum(BuildContext context, Album album) async {
    // This could open a photo picker based on all photos
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecteer foto\'s in de gallerij en kies "Voeg toe aan album"')));
  }
}
