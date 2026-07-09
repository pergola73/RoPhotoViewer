import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kphoto/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';

import 'package:kphoto/presentation/blocs/gallery_bloc.dart';

import 'package:kphoto/presentation/screens/photo_viewer_screen.dart';
import 'package:kphoto/presentation/screens/settings_screen.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:share_plus/share_plus.dart';

import 'package:kphoto/presentation/screens/slideshow_screen.dart';
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
  
  // Fast Scroll states
  bool _isDragging = false;
  double _dragOffset = 0.0;
  String _scrollLabel = '';
  DateTime? _lastHapticDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Start automatische sync op de achtergrond bij openen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryBloc>().add(LoadGallery());
      context.read<GalleryBloc>().add(SyncWithKDrive());
    });
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<GalleryBloc>().add(LoadMorePhotos());
    }
    if (!_isDragging) {
      setState(() {}); // Update scroller position during normal scroll
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
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
    final double targetScroll = scrollPercent * _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(targetScroll);

    // Update label based on currently visible photo (estimated)
    final int index = (state.photos.length * scrollPercent).floor().clamp(0, state.photos.length - 1);
    final photo = state.photos[index];
    
    final newLabel = _getScrollLabel(photo.dateTaken, state.totalPhotoCount);
    if (newLabel != _scrollLabel) {
      setState(() {
        _scrollLabel = newLabel;
      });
      
      // Haptic feedback when passing a "boundary" (e.g., new year or month)
      if (_lastHapticDate == null || _shouldTriggerHaptic(_lastHapticDate!, photo.dateTaken)) {
        HapticFeedback.selectionClick();
        _lastHapticDate = photo.dateTaken;
      }
    }
  }

  String _getScrollLabel(DateTime date, int totalCount) {
    if (totalCount > 1000) {
      return date.year.toString();
    } else if (totalCount > 100) {
      return DateFormat('MMM yyyy', 'nl_NL').format(date);
    } else {
      return DateFormat('d MMM', 'nl_NL').format(date);
    }
  }

  bool _shouldTriggerHaptic(DateTime last, DateTime current) {
    // Trigger als jaar verandert, of maand als er minder foto's zijn
    return last.year != current.year || (last.month != current.month);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
                Tab(icon: Icon(Icons.people), text: 'Personen'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildPhotosTab(context),
            _buildAlbumsTab(context),
            _buildPeopleTab(context),
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
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<GalleryBloc>().add(SyncWithKDrive());
                    await context.read<GalleryBloc>().stream.firstWhere((state) => state.status != GalleryStatus.syncing).timeout(const Duration(seconds: 30), onTimeout: () => state);
                  },
                  child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (state.status == GalleryStatus.syncing)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          color: Colors.blue.withOpacity(0.1),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Synchroniseren met kDrive...',
                                      style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '${state.processedCount} items',
                                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const LinearProgressIndicator(minHeight: 2),
                            ],
                          ),
                        ),
                      ),

                    if (state.isAiScanning)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          color: Colors.purple.withOpacity(0.1),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'AI Analyse bezig...',
                                      style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '${state.aiScanCurrent}/${state.aiScanTotal}',
                                    style: TextStyle(color: Colors.purple.shade700, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: state.aiScanTotal > 0 ? state.aiScanCurrent / state.aiScanTotal : null,
                                backgroundColor: Colors.purple.withOpacity(0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                                minHeight: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    if (state.status == GalleryStatus.loading && state.photos.isEmpty)
                      const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                    
                    if (state.photos.isEmpty && state.status != GalleryStatus.loading && state.status != GalleryStatus.syncing)
                      const SliverFillRemaining(child: Center(child: Text('Geen foto\'s gevonden.'))),

                    for (var section in sortedSections)
                      SliverStickyHeader(
                        header: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            final sectionPhotos = state.groupedPhotos[section]!;
                            context.read<GalleryBloc>().add(SelectSection(sectionPhotos.map((p) => p.id).toList()));
                          },
                          child: Container(
                            height: 50.0,
                            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  section,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                if (isSelectionMode)
                                  Icon(
                                    state.groupedPhotos[section]!.every((p) => state.selectedPhotoIds.contains(p.id))
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                              ],
                            ),
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
                                    HapticFeedback.lightImpact();
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
                                  HapticFeedback.mediumImpact();
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
                                                  Image.file(
                                                    File(photo.localThumbnailPath!),
                                                    fit: BoxFit.cover,
                                                    cacheWidth: crossAxisCount == 1 ? 800 : 400,
                                                    filterQuality: FilterQuality.low,
                                                  ),
                                                  if ((crossAxisCount <= 2) && photo.localHighResPath != null && File(photo.localHighResPath!).existsSync() && photo.mediaType == 'image')
                                                    Image.file(
                                                      File(photo.localHighResPath!),
                                                      fit: BoxFit.cover,
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
                    
                    if (!state.hasReachedMax && state.photos.isNotEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)), // Ruimte onderaan voor makkelijker scrollen
                  ],
                ),
              ),
              
              // Custom Fast Scroller Overlay
              if (state.photos.isNotEmpty)
                _buildFastScroller(context, state),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildFastScroller(BuildContext context, GalleryState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight - 100; // Ruimte voor de handle
        double currentThumbOffset = 0.0;
        
        if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
          if (_isDragging) {
            currentThumbOffset = _dragOffset;
          } else {
            final scrollPercent = _scrollController.offset / _scrollController.position.maxScrollExtent;
            currentThumbOffset = (scrollPercent * maxHeight).clamp(0.0, maxHeight);
            // We updaten _dragOffset niet hier om verspringen te voorkomen tijdens drag
          }
        }

        return Stack(
          children: [
            // Het Label (De "Bubble") - Gefixeerd op 1/4 van de bovenkant zoals gevraagd
            if (_isDragging)
              Positioned(
                top: constraints.maxHeight * 0.25,
                right: 60,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(
                    _scrollLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),

            // De Slider Handle
            Positioned(
              top: currentThumbOffset + 50, // Kleine offset vanaf boven
              right: 8,
              child: GestureDetector(
                onVerticalDragStart: (details) {
                  setState(() {
                    _isDragging = true;
                    _dragOffset = currentThumbOffset;
                    HapticFeedback.lightImpact();
                  });
                },
                onVerticalDragUpdate: (details) => _onDragUpdate(details, maxHeight, state),
                onVerticalDragEnd: (_) => setState(() {
                  _isDragging = false;
                  _lastHapticDate = null;
                }),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isDragging ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.4),
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (_isDragging)
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Icon(
                    Icons.unfold_more,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
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
          icon: const Icon(Icons.play_circle_outline),
          onPressed: () => _startSlideshow(state, random: true),
          tooltip: 'Slideshow (Random)',
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
          icon: const Icon(Icons.select_all),
          onPressed: () => context.read<GalleryBloc>().add(SelectAll()),
          tooltip: 'Alles selecteren',
        ),
        IconButton(
          icon: const Icon(Icons.slideshow),
          onPressed: () => _startSlideshow(state),
          tooltip: 'Slideshow selectie',
        ),
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

  void _startSlideshow(GalleryState state, {bool random = false}) {
    List<Photo> slideshowPhotos;
    if (state.selectedPhotoIds.isNotEmpty) {
      slideshowPhotos = state.photos.where((p) => state.selectedPhotoIds.contains(p.id)).toList();
    } else {
      slideshowPhotos = state.photos;
    }

    if (slideshowPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geen foto\'s om te tonen')));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SlideshowScreen(
          photos: slideshowPhotos,
          randomize: random,
        ),
      ),
    );
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
        title: const Text('Foto\'s verplaatsen'),
        content: Text('Wat wil je doen met deze ${state.selectedPhotoIds.length} foto\'s?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 1),
            child: const Text('Alleen lokaal verwijderen', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 2),
            child: const Text('Naar kDrive prullenbak', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == 1) {
      context.read<GalleryBloc>().add(const DeleteSelectedPhotos(remoteToo: false));
      context.read<GalleryBloc>().add(ClearSelection());
    } else if (result == 2) {
      context.read<GalleryBloc>().add(const DeleteSelectedPhotos(remoteToo: true, permanent: false));
      context.read<GalleryBloc>().add(ClearSelection());
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

  Widget _buildPeopleTab(BuildContext context) {
    final db = context.read<GalleryBloc>().db;
    return StreamBuilder<List<Person>>(
      stream: db.select(db.persons).watch(),
      builder: (context, snapshot) {
        final persons = snapshot.data ?? [];

        return Column(
          children: [
            if (persons.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.face_retouching_natural, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Nog geen personen herkend.'),
                      Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'Scan je foto\'s via Instellingen > AI Tags opnieuw scannen om gezichten te ontdekken.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: persons.length,
                  itemBuilder: (context, index) {
                    final person = persons[index];
                    return GestureDetector(
                      onTap: () => _openPersonGallery(context, person),
                      onLongPress: () => _showPersonOptions(context, person),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2),
                                image: person.faceSamplePath != null && File(person.faceSamplePath!).existsSync()
                                    ? DecorationImage(image: FileImage(File(person.faceSamplePath!)), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: person.faceSamplePath == null ? const Icon(Icons.person, color: Colors.grey) : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            person.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          FutureBuilder<List<Photo>>(
                            future: db.getPhotosForPerson(person.id),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.length ?? 0;
                              return Text(
                                '$count ${count == 1 ? "foto" : "foto\'s"}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            
            // Toon gedetecteerde maar nog niet benoemde gezichten
            _buildUnnamedFacesSection(context),
          ],
        );
      },
    );
  }

  Widget _buildUnnamedFacesSection(BuildContext context) {
    final db = context.read<GalleryBloc>().db;
    return FutureBuilder<List<DetectedFace>>(
      future: (db.select(db.detectedFaces)..where((t) => t.personId.isNull())).get(),
      builder: (context, snapshot) {
        final faces = snapshot.data ?? [];
        if (faces.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 150,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            border: Border(top: BorderSide(color: Colors.blue.withOpacity(0.1))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Nieuwe gezichten gevonden', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: faces.length,
                  itemBuilder: (context, index) {
                    final face = faces[index];
                    return GestureDetector(
                      onTap: () => _nameAFace(context, face),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: face.faceThumbnailPath != null && File(face.faceThumbnailPath!).existsSync()
                              ? DecorationImage(image: FileImage(File(face.faceThumbnailPath!)), fit: BoxFit.cover)
                              : null,
                        ),
                        child: face.faceThumbnailPath == null ? const Icon(Icons.face) : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _nameAFace(BuildContext context, DetectedFace face) async {
    final controller = TextEditingController();
    final db = context.read<GalleryBloc>().db;
    final existingPersons = await db.getAllPersons();

    if (!context.mounted) return;

    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wie is dit?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (face.faceThumbnailPath != null)
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: FileImage(File(face.faceThumbnailPath!)), fit: BoxFit.cover),
                ),
              ),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Naam van de persoon'),
            ),
            if (existingPersons.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Of kies een bestaand persoon:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                width: double.maxFinite,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: existingPersons.length,
                  itemBuilder: (context, i) {
                    final p = existingPersons[i];
                    return ActionChip(
                      label: Text(p.name),
                      onPressed: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Opslaan')),
        ],
      ),
    );

    if (result != null) {
      int personId;
      String name;
      if (result is Person) {
        personId = result.id;
        name = result.name;
      } else {
        name = result.toString().trim();
        if (name.isEmpty) return;
        // Gebruik de nieuwe getOrCreate methode om dubbelen te voorkomen
        personId = await db.getOrCreatePerson(name, faceSamplePath: face.faceThumbnailPath);
      }

      await db.assignPersonToFace(face.id, personId);
      
      // Update ook de 'people' string in de Photo record voor makkelijk zoeken
      final photo = await (db.select(db.photos)..where((t) => t.id.equals(face.photoId))).getSingle();
      final currentPeople = photo.people?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() ?? [];
      
      if (!currentPeople.contains(name)) {
        currentPeople.add(name);
        await (db.update(db.photos)..where((t) => t.id.equals(photo.id))).write(
          PhotosCompanion(people: Value(currentPeople.join(', '))),
        );
      }

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name gekoppeld aan gezicht')));
      }
    }
  }

  void _openPersonGallery(BuildContext context, Person person) async {
    final db = context.read<GalleryBloc>().db;
    final photos = await db.getPhotosForPerson(person.id);
    if (!context.mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(person.name),
              Text('${photos.length} foto\'s gevonden', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          ),
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
              onLongPress: () => _showUnlinkPersonDialog(context, person, photo),
              child: photo.localThumbnailPath != null
                ? Image.file(File(photo.localThumbnailPath!), fit: BoxFit.cover)
                : const Icon(Icons.photo),
            );
          },
        ),
      ),
    ));
  }

  void _showUnlinkPersonDialog(BuildContext context, Person person, Photo photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Persoon loskoppelen?'),
        content: Text('Wil je ${person.name} verwijderen van deze foto? De foto zelf blijft bewaard.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          TextButton(
            onPressed: () async {
              final db = context.read<GalleryBloc>().db;
              // Zoek de gedetecteerde gezichten voor deze foto die aan deze persoon gekoppeld zijn
              final faces = await db.getFacesForPhoto(photo.id);
              for (var face in faces) {
                if (face.personId == person.id) {
                  // Ontkoppel de persoon van het gezicht
                  await (db.update(db.detectedFaces)..where((t) => t.id.equals(face.id))).write(
                    const DetectedFacesCompanion(personId: Value(null)),
                  );
                }
              }
              
              // Update de 'people' string in de foto record
              final currentPeople = photo.people?.split(',').map((s) => s.trim()).toList() ?? [];
              currentPeople.remove(person.name);
              await (db.update(db.photos)..where((t) => t.id.equals(photo.id))).write(
                PhotosCompanion(people: Value(currentPeople.isEmpty ? null : currentPeople.join(', '))),
              );

              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context); // Sluit gallerij en heropen om te verversen
                _openPersonGallery(context, person);
              }
            },
            child: const Text('Loskoppelen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPersonOptions(BuildContext context, Person person) {
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
                final controller = TextEditingController(text: person.name);
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
                  final db = context.read<GalleryBloc>().db;
                  await (db.update(db.persons)..where((t) => t.id.equals(person.id))).write(
                    PersonsCompanion(name: Value(result)),
                  );
                  // Merk op: de 'people' string in Photos blijft hierbij ongewijzigd in dit simpele model
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Persoon verwijderen', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Verwijderen?'),
                    content: Text('Weet je zeker dat je "${person.name}" wilt verwijderen? De koppelingen worden verbroken.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuleren')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verwijderen', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  final db = context.read<GalleryBloc>().db;
                  // Verwijder koppelingen bij gezichten
                  await (db.update(db.detectedFaces)..where((t) => t.personId.equals(person.id))).write(
                    const DetectedFacesCompanion(personId: Value(null)),
                  );
                  // Verwijder persoon
                  await (db.delete(db.persons)..where((t) => t.id.equals(person.id))).go();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
