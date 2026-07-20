import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kphoto/core/database/app_database.dart';
import 'package:intl/intl.dart';
import 'package:kphoto/presentation/blocs/gallery_bloc.dart';
import 'package:kphoto/presentation/screens/photo_viewer_screen.dart';
import 'package:kphoto/presentation/screens/settings_screen.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kphoto/core/services/permission_service.dart';

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
  bool _isDragging = false;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PermissionService.checkAndRequestPermissions(context);
      if (mounted) {
        context.read<GalleryBloc>().add(LoadGallery());
        context.read<GalleryBloc>().add(SyncWithKDrive());
      }
    });
  }

  void _onScroll() {
    if (_isBottom) context.read<GalleryBloc>().add(LoadMorePhotos());
    if (!_isDragging) setState(() {}); 
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    return _scrollController.offset >= (_scrollController.position.maxScrollExtent * 0.9);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxHeight, GalleryState state) {
    if (!_scrollController.hasClients || state.photos.isEmpty) return;
    setState(() {
      _isDragging = true;
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, maxHeight);
    });
    final double scrollPercent = _dragOffset / maxHeight;
    _scrollController.jumpTo(scrollPercent * _scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        bottomNavigationBar: Material(
          elevation: 8,
          color: Theme.of(context).cardColor,
          child: const SafeArea(
            child: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.photo_library), text: 'Foto\'s'),
                Tab(icon: Icon(Icons.collections), text: 'Albums'),
                Tab(icon: Icon(Icons.people), text: 'Personen'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildPhotosTab(context),
            _buildAlbumsTab(context),
            _buildPersonsTab(context),
          ],
        ),
        floatingActionButton: BlocBuilder<GalleryBloc, GalleryState>(
          builder: (context, state) {
            if (state.selectedPhotoIds.isNotEmpty) return const SizedBox.shrink();
            return FloatingActionButton(
              onPressed: () => context.read<GalleryBloc>().add(const SyncWithKDrive(isManual: true)),
              child: state.isSyncing 
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
        int crossAxisCount = state.viewMode == GalleryViewMode.large ? 1 : (state.viewMode == GalleryViewMode.day ? 2 : 4);

        return Scaffold(
          appBar: isSelectionMode 
            ? _buildSelectionAppBar(context, state)
            : _buildNormalAppBar(context, state),
          body: GestureDetector(
            onScaleStart: (_) => _baseScale = 1.0,
            onScaleUpdate: (details) {
              final scale = details.scale;
              if ((scale - _baseScale).abs() > 0.3) {
                if (scale > 1.2) {
                  if (state.viewMode == GalleryViewMode.month) context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.day));
                  else if (state.viewMode == GalleryViewMode.day) context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.large));
                  _baseScale = scale;
                } else if (scale < 0.8) {
                  if (state.viewMode == GalleryViewMode.large) context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.day));
                  else if (state.viewMode == GalleryViewMode.day) context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.month));
                  _baseScale = scale;
                }
              }
            },
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async => context.read<GalleryBloc>().add(const SyncWithKDrive(isManual: true)),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      if (state.photos.isEmpty && state.status != GalleryStatus.loading)
                        const SliverFillRemaining(child: Center(child: Text('Geen foto\'s gevonden.'))),

                      for (var section in sortedSections)
                        SliverStickyHeader(
                          header: _buildSectionHeader(context, section, state, isSelectionMode),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 2,
                              crossAxisSpacing: 2,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildPhotoItem(context, state.groupedPhotos[section]![index], state, isSelectionMode, crossAxisCount),
                              childCount: state.groupedPhotos[section]!.length,
                            ),
                          ),
                        ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                    ],
                  ),
                ),
                if (state.photos.isNotEmpty) _buildFastScroller(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildNormalAppBar(BuildContext context, GalleryState state) {
    return AppBar(
      title: _isSearching 
        ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Zoek...', border: InputBorder.none),
            onSubmitted: (q) => context.read<GalleryBloc>().add(SemanticSearch(q)),
          )
        : const Text('K-Photo', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        if (state.isSyncing && state.isManualSync || state.isAiScanning)
          _buildSubtleProgress(state),
        IconButton(
          icon: Icon(state.showOnlyFavorites ? Icons.star : Icons.star_border),
          onPressed: () => context.read<GalleryBloc>().add(ToggleFavoriteFilter()),
        ),
        IconButton(
          icon: Icon(state.viewMode == GalleryViewMode.month ? Icons.grid_view : (state.viewMode == GalleryViewMode.day ? Icons.view_module : Icons.view_agenda)),
          onPressed: () {
            final nextMode = state.viewMode == GalleryViewMode.month 
              ? GalleryViewMode.day : (state.viewMode == GalleryViewMode.day ? GalleryViewMode.large : GalleryViewMode.month);
            context.read<GalleryBloc>().add(ChangeViewMode(nextMode));
          },
        ),
        IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search), onPressed: () => setState(() => _isSearching = !_isSearching)),
        IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(BuildContext context, GalleryState state) {
    return AppBar(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.read<GalleryBloc>().add(ClearSelection())),
      title: Text('${state.selectedPhotoIds.length} geselecteerd'),
      actions: [
        IconButton(
          icon: const Icon(Icons.star), 
          onPressed: () => context.read<GalleryBloc>().add(ToggleSelectedPhotosFavorite()),
        ),
        IconButton(icon: const Icon(Icons.share), onPressed: () => _shareSelected(state)),
        IconButton(icon: const Icon(Icons.add_to_photos), onPressed: () => _addToAlbumSelected(state)),
        IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context)),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String section, GalleryState state, bool isSelectionMode) {
    final sectionPhotos = state.groupedPhotos[section]!;
    final bool allSelected = sectionPhotos.every((p) => state.selectedPhotoIds.contains(p.id));

    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          context.read<GalleryBloc>().add(SelectSection(sectionPhotos.map((p) => p.id).toList()));
        }
      },
      child: Container(
        height: 40,
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(section, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (isSelectionMode)
              Icon(allSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: Colors.blue, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(BuildContext context, Photo photo, GalleryState state, bool isSelectionMode, int crossAxisCount) {
    final isSelected = state.selectedPhotoIds.contains(photo.id);
    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          context.read<GalleryBloc>().add(TogglePhotoSelection(photo.id));
        } else {
          final fullIndex = state.photos.indexOf(photo);
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => PhotoViewerScreen(photos: state.photos, initialIndex: fullIndex >= 0 ? fullIndex : 0)));
        }
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        context.read<GalleryBloc>().add(TogglePhotoSelection(photo.id));
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.grey[200],
            child: (photo.localThumbnailPath != null && File(photo.localThumbnailPath!).existsSync())
                ? Image.file(
                    File(photo.localThumbnailPath!), 
                    fit: BoxFit.cover, 
                    cacheWidth: crossAxisCount == 1 ? 800 : (crossAxisCount == 2 ? 400 : 250),
                  )
                : const Icon(Icons.photo, color: Colors.white),
          ),
          if (photo.isFavorite)
            const Positioned(top: 4, right: 4, child: Icon(Icons.star, color: Colors.yellow, size: 16)),
          if (isSelected)
            Container(
              color: Colors.white.withOpacity(0.3),
              child: const Center(child: Icon(Icons.check_circle, color: Colors.blue, size: 30)),
            ),
        ],
      ),
    );
  }

  Widget _buildSubtleProgress(GalleryState state) {
    String countText = '${state.processedCount}';
    String message = 'Synchroniseren met kDrive...';
    
    if (state.isAiScanning || state.isIndexing) {
      countText = '${state.indexingCurrent}';
      message = 'Google AI Analyse bezig...';
    }

    final Color color = (state.isAiScanning || state.isIndexing) ? Colors.purple : Colors.blue;

    return Tooltip(
      message: message,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10, height: 10, 
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              )
            ),
            const SizedBox(width: 4),
            Text(
              countText, 
              style: TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.bold, 
                color: color
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFastScroller(BuildContext context, GalleryState state) {
    return Positioned(
      right: 4, top: 100, bottom: 100,
      child: GestureDetector(
        onVerticalDragUpdate: (d) => _onDragUpdate(d, MediaQuery.of(context).size.height - 200, state),
        onVerticalDragEnd: (_) => setState(() => _isDragging = false),
        child: Container(
          width: 30,
          decoration: BoxDecoration(color: _isDragging ? Colors.blue.withOpacity(0.3) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
          child: Center(
            child: Container(
              width: 6, height: 60,
              decoration: BoxDecoration(color: _isDragging ? Colors.blue : Colors.blueGrey.withOpacity(0.5), borderRadius: BorderRadius.circular(3)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumsTab(BuildContext context) {
    return StreamBuilder<List<Album>>(
      stream: AppDatabase().watchAllAlbums(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Geen albums gevonden.\nSelecteer fotos om een album te maken.', textAlign: TextAlign.center));
        }
        final albums = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, 
            mainAxisSpacing: 16, 
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return GestureDetector(
              onTap: () {
                // TODO: Open album detail screen
              },
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50, 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: const Center(child: Icon(Icons.photo_album, size: 50, color: Colors.blue)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(album.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPersonsTab(BuildContext context) {
    return FutureBuilder<List<Person>>(
      future: AppDatabase().getAllPersons(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Icon(Icons.face, size: 64, color: Colors.grey), 
                SizedBox(height: 16), 
                Text('Nog geen personen herkend.\nZorg dat de AI Analyse voltooid is.', textAlign: TextAlign.center),
              ],
            ),
          );
        }
        final persons = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: persons.length,
          itemBuilder: (context, index) {
            final person = persons[index];
            return Column(
              children: [
                Expanded(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.purple.shade50,
                    backgroundImage: person.faceSamplePath != null ? FileImage(File(person.faceSamplePath!)) : null,
                    child: person.faceSamplePath == null ? const Icon(Icons.person, size: 40, color: Colors.purple) : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(person.name, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            );
          },
        );
      },
    );
  }

  void _shareSelected(GalleryState state) async {
    final selectedPhotos = state.photos.where((p) => state.selectedPhotoIds.contains(p.id)).toList();
    final paths = selectedPhotos.map((p) => p.localHighResPath ?? p.localThumbnailPath).whereType<String>().map((path) => XFile(path)).toList();
    if (paths.isNotEmpty) await Share.shareXFiles(paths);
  }

  void _addToAlbumSelected(GalleryState state) async {
    final db = AppDatabase();
    final albums = await db.getAllAlbums();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.add), title: const Text('Nieuw Album'), onTap: () { Navigator.pop(context); _createNewAlbumWithSelected(state); }),
            const Divider(),
            ...albums.map((album) => ListTile(
              leading: const Icon(Icons.photo_album), title: Text(album.name),
              onTap: () async {
                for (var photoId in state.selectedPhotoIds) { await db.addPhotoToAlbum(album.id, photoId); }
                if (mounted) { Navigator.pop(context); context.read<GalleryBloc>().add(ClearSelection()); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Toegevoegd aan ${album.name}'))); }
              },
            )),
          ],
        ),
      ),
    );
  }

  void _createNewAlbumWithSelected(GalleryState state) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuw Album'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Album naam')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Maken')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final db = AppDatabase();
      final albumId = await db.createAlbum(result, coverPhotoId: state.selectedPhotoIds.first);
      for (var photoId in state.selectedPhotoIds) { await db.addPhotoToAlbum(albumId, photoId); }
      context.read<GalleryBloc>().add(ClearSelection());
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geselecteerde foto\'s verwijderen?'),
        content: const Text('Wil je deze foto\'s alleen van je telefoon verwijderen, of ook uit de kDrive prullenbak?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULEREN')),
          TextButton(onPressed: () { context.read<GalleryBloc>().add(const DeleteSelectedPhotos(remoteToo: false)); Navigator.pop(context); }, child: const Text('ALLEEN LOKAAL')),
          ElevatedButton(onPressed: () { context.read<GalleryBloc>().add(const DeleteSelectedPhotos(remoteToo: true)); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('K-DRIVE PRULLENBAK')),
        ],
      ),
    );
  }
}
