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
  
  // Fast Scroll states
  bool _isDragging = false;
  double _dragOffset = 0.0;
  String _scrollLabel = '';
  DateTime? _lastHapticDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PermissionService.checkAndRequestPermissions(context);
      if (mounted) {
        context.read<GalleryBloc>().add(LoadGallery());
        // Start automatische sync op de achtergrond
        context.read<GalleryBloc>().add(SyncWithKDrive());
      }
    });
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<GalleryBloc>().add(LoadMorePhotos());
    }
    if (!_isDragging) {
      setState(() {}); 
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

    final int index = (state.photos.length * scrollPercent).floor().clamp(0, state.photos.length - 1);
    final photo = state.photos[index];
    
    final newLabel = _getScrollLabel(photo.dateTaken, state.totalPhotoCount);
    if (newLabel != _scrollLabel) {
      setState(() {
        _scrollLabel = newLabel;
      });
      if (_lastHapticDate == null || _shouldTriggerHaptic(_lastHapticDate!, photo.dateTaken)) {
        HapticFeedback.selectionClick();
        _lastHapticDate = photo.dateTaken;
      }
    }
  }

  String _getScrollLabel(DateTime date, int totalCount) {
    if (totalCount > 1000) return date.year.toString();
    return DateFormat('MMM yyyy', 'nl_NL').format(date);
  }

  bool _shouldTriggerHaptic(DateTime last, DateTime current) {
    return last.year != current.year || last.month != current.month;
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
            const Center(child: Text('Albums Coming Soon')),
            const Center(child: Text('Personen Coming Soon')),
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
                if (scale > 1.3) {
                  if (state.viewMode == GalleryViewMode.month) context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.day));
                  else if (state.viewMode == GalleryViewMode.day) context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.large));
                  _baseScale = scale;
                } else if (scale < 0.7) {
                  if (state.viewMode == GalleryViewMode.large) context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.day));
                  else if (state.viewMode == GalleryViewMode.day) context.read<GalleryBloc>().add(const ChangeViewMode(GalleryViewMode.month));
                  _baseScale = scale;
                }
              }
            },
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<GalleryBloc>().add(SyncWithKDrive());
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (state.status == GalleryStatus.syncing || state.status == GalleryStatus.initialSync || state.isAiScanning || state.isIndexing)
                        SliverToBoxAdapter(child: _buildSyncDashboard(context, state)),
                      
                      if (state.status == GalleryStatus.loading && state.photos.isEmpty)
                        const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                      
                      if (state.photos.isEmpty && state.status != GalleryStatus.loading && state.status != GalleryStatus.syncing && state.status != GalleryStatus.initialSync)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.folder_off, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text('Geen mappen geselecteerd of mappen zijn leeg.'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                                  child: const Text('INSTELLINGEN OPENEN'),
                                ),
                              ],
                            ),
                          ),
                        ),

                      for (var section in sortedSections)
                        SliverStickyHeader(
                          header: _buildSectionHeader(context, section, state, isSelectionMode),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 1,
                              crossAxisSpacing: 1,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildPhotoItem(context, state.groupedPhotos[section]![index], state, isSelectionMode, crossAxisCount),
                              childCount: state.groupedPhotos[section]!.length,
                            ),
                          ),
                        ),
                      
                      if (!state.hasReachedMax && state.photos.isNotEmpty)
                        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator()))),
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

  Widget _buildSectionHeader(BuildContext context, String section, GalleryState state, bool isSelectionMode) {
    return GestureDetector(
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
            Text(section, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (isSelectionMode)
              Icon(
                state.groupedPhotos[section]!.every((p) => state.selectedPhotoIds.contains(p.id)) ? Icons.check_circle : Icons.radio_button_unchecked,
                color: Colors.blue, size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(BuildContext context, Photo photo, GalleryState state, bool isSelectionMode, int crossAxisCount) {
    final isSelected = state.selectedPhotoIds.contains(photo.id);
    return GestureDetector(
      key: ValueKey(photo.id),
      onTap: () {
        if (isSelectionMode) {
          context.read<GalleryBloc>().add(TogglePhotoSelection(photo.id));
        } else {
          final fullIndex = state.photos.indexOf(photo);
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => PhotoViewerScreen(photos: state.photos, initialIndex: fullIndex >= 0 ? fullIndex : 0)));
        }
      },
      onLongPress: () => context.read<GalleryBloc>().add(TogglePhotoSelection(photo.id)),
      child: Hero(
        tag: photo.id,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.grey[300],
              child: (photo.localThumbnailPath != null && File(photo.localThumbnailPath!).existsSync())
                  ? Image.file(
                      File(photo.localThumbnailPath!),
                      fit: BoxFit.cover,
                      cacheWidth: crossAxisCount == 1 ? 800 : 400,
                    )
                  : const Center(child: Icon(Icons.photo, color: Colors.white, size: 20)),
            ),
            if (isSelected) Container(color: Colors.white.withOpacity(0.3), child: const Center(child: Icon(Icons.check_circle, color: Colors.blue, size: 30))),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncDashboard(BuildContext context, GalleryState state) {
    String title = 'Synchroniseren...';
    IconData icon = Icons.sync;
    Color color = Colors.blue;
    double? progress;
    String subtitle = '';

    if (state.syncPhase == SyncPhase.scanning) {
      title = 'kDrive scannen...';
      icon = Icons.search;
      subtitle = '${state.processedCount} items gevonden';
    } else if (state.syncPhase == SyncPhase.downloading) {
      title = 'Plaatjes ophalen...';
      icon = Icons.download;
      progress = state.totalPhotoCount > 0 ? state.processedCount / state.totalPhotoCount : null;
      subtitle = '${state.processedCount} van ${state.totalPhotoCount}';
    } else if (state.isIndexing || state.isAiScanning) {
      title = 'Zoekmachine vullen...';
      icon = Icons.auto_awesome;
      color = Colors.purple;
      progress = state.indexingTotal > 0 ? state.indexingCurrent / state.indexingTotal : null;
      subtitle = '${state.indexingCurrent} van ${state.indexingTotal}';
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13))),
              if (state.estimatedTimeRemaining != null) Text(state.estimatedTimeRemaining!, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 2),
          if (subtitle.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: TextStyle(fontSize: 10, color: color))),
        ],
      ),
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
        : const Text('K-Photo'),
      actions: [
        IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search), onPressed: () => setState(() => _isSearching = !_isSearching)),
        IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(BuildContext context, GalleryState state) {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.read<GalleryBloc>().add(ClearSelection())),
      title: Text('${state.selectedPhotoIds.length} geselecteerd'),
      actions: [
        IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context)),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Foto\'s verwijderen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          TextButton(onPressed: () {
            context.read<GalleryBloc>().add(const DeleteSelectedPhotos(remoteToo: true));
            Navigator.pop(context);
          }, child: const Text('Verwijderen', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildFastScroller(BuildContext context, GalleryState state) {
    return Positioned(
      right: 0, top: 0, bottom: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (d) => _onDragUpdate(d, MediaQuery.of(context).size.height - 100, state),
        onVerticalDragEnd: (_) => setState(() => _isDragging = false),
        child: Container(width: 40, color: Colors.transparent),
      ),
    );
  }
}
