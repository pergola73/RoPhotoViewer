import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ro_photo_viewer/core/database/app_database.dart';
import 'package:ro_photo_viewer/core/network/auth_repository.dart';
import 'package:ro_photo_viewer/core/network/kdrive_api_service.dart';
import 'package:ro_photo_viewer/presentation/blocs/gallery_bloc.dart';
import 'package:ro_photo_viewer/presentation/screens/login_screen.dart';
import 'package:ro_photo_viewer/presentation/screens/photo_viewer_screen.dart';
import 'package:ro_photo_viewer/presentation/screens/settings_screen.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.photo_library), text: 'Foto\'s'),
            Tab(icon: Icon(Icons.collections), text: 'Albums'),
          ],
        ),
        body: TabBarView(
          children: [
            _buildPhotosTab(context),
            _buildAlbumsTab(context),
          ],
        ),
        floatingActionButton: BlocBuilder<GalleryBloc, GalleryState>(
          builder: (context, state) => FloatingActionButton(
            onPressed: () => context.read<GalleryBloc>().add(SyncWithKDrive()),
            child: state.status == GalleryStatus.syncing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.sync),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosTab(BuildContext context) {
    return BlocListener<GalleryBloc, GalleryState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == GalleryStatus.syncing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sync gestart...'), duration: Duration(seconds: 2)),
          );
        } else if (state.status == GalleryStatus.syncFinished) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sync voltooid!'), backgroundColor: Colors.green),
          );
        }
      },
      child: BlocBuilder<GalleryBloc, GalleryState>(
        builder: (context, state) {
          final months = state.groupedPhotos.keys.toList();
          int crossAxisCount = 4;
          if (state.viewMode == GalleryViewMode.large) crossAxisCount = 1;
          if (state.viewMode == GalleryViewMode.day) crossAxisCount = 2;
          if (state.viewMode == GalleryViewMode.month) crossAxisCount = 4;

          return GestureDetector(
            onScaleEnd: (details) {
              if (details.scaleVelocity > 0.5) {
                if (state.viewMode == GalleryViewMode.month) {
                  context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.day));
                } else if (state.viewMode == GalleryViewMode.day) {
                  context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.large));
                }
              } else if (details.scaleVelocity < -0.5) {
                if (state.viewMode == GalleryViewMode.large) {
                  context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.day));
                } else if (state.viewMode == GalleryViewMode.day) {
                  context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.month));
                }
              }
            },
            child: CustomScrollView(
              cacheExtent: 2000.0,
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('K-Photo ${state.photos.isNotEmpty ? "(${state.photos.length})" : ""}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      if (state.status == GalleryStatus.syncing)
                        Text('Syncing: ${state.processedCount}...', 
                          style: const TextStyle(fontSize: 12, color: Colors.blue)),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
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
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        final auth = AuthRepository();
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => LoginScreen(authRepository: auth, apiService: KDriveApiService()))
                          );
                        }
                      },
                    ),
                  ],
                ),
                if (state.status == GalleryStatus.loading && state.photos.isEmpty)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                
                if (state.photos.isEmpty && state.status != GalleryStatus.loading && state.status != GalleryStatus.syncing)
                  const SliverFillRemaining(child: Center(child: Text('Geen foto\'s gevonden.'))),

                for (var month in months) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        month,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ),
                  ),
                  SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final photo = state.groupedPhotos[month]![index];
                        return GestureDetector(
                          key: ValueKey(photo.id),
                          onTap: () {
                            final fullIndex = state.photos.indexOf(photo);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PhotoViewerScreen(
                                  photos: state.photos,
                                  initialIndex: fullIndex >= 0 ? fullIndex : 0,
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: photo.id,
                            child: Container(
                              color: Colors.grey[300],
                              child: (photo.localThumbnailPath != null && File(photo.localThumbnailPath!).existsSync())
                                  ? Image.file(
                                      File(photo.localThumbnailPath!),
                                      fit: BoxFit.cover,
                                      cacheWidth: crossAxisCount == 1 ? 800 : 200,
                                    )
                                  : Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Icon(Icons.photo, color: Colors.white, size: 20),
                                        Positioned(
                                          bottom: 2,
                                          child: Text(
                                            photo.fileName.length > 10 ? '...${photo.fileName.substring(photo.fileName.length - 8)}' : photo.fileName,
                                            style: const TextStyle(fontSize: 8, color: Colors.black54),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                      },
                      childCount: state.groupedPhotos[month]!.length,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlbumsTab(BuildContext context) {
    final db = context.read<GalleryBloc>().db;
    return FutureBuilder<List<Album>>(
      future: db.getAllAlbums(),
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
                      ),
                      child: const Center(child: Icon(Icons.photo_album, size: 40, color: Colors.grey)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(album.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
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
        appBar: AppBar(title: Text(album.name)),
        body: GridView.builder(
          padding: const EdgeInsets.all(1),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1, mainAxisSpacing: 1),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return Image.file(File(photo.localThumbnailPath!), fit: BoxFit.cover);
          },
        ),
      ),
    ));
  }
}
