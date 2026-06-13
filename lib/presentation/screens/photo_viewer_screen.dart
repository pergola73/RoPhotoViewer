import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:ro_photo_viewer/core/database/app_database.dart';
import 'package:ro_photo_viewer/core/network/kdrive_api_service.dart';
import 'package:ro_photo_viewer/core/network/auth_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, bool> _isDownloading = {};
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _downloadHighRes(_currentIndex);
  }

  Future<void> _downloadHighRes(int index) async {
    if (index < 0 || index >= widget.photos.length) return;
    final photo = widget.photos[index];

    if (photo.localHighResPath != null && File(photo.localHighResPath!).existsSync()) return;
    if (_isDownloading[photo.id] == true) return;

    setState(() => _isDownloading[photo.id] = true);

    try {
      final auth = AuthRepository();
      final creds = await auth.getCredentials();
      final api = KDriveApiService();
      await api.initialize(creds['token']!, creds['driveId']!);

      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(dir.path, 'photos'));
      if (!photosDir.existsSync()) photosDir.createSync();
      
      final localPath = p.join(photosDir.path, photo.fileName);
      await api.downloadFile(photo.kdrivePath, localPath);

      if (File(localPath).existsSync() && mounted) {
        final db = AppDatabase();
        await (db.update(db.photos)..where((t) => t.id.equals(photo.id))).write(
          PhotosCompanion(localHighResPath: Value(localPath)),
        );
        
        setState(() {
          widget.photos[index] = photo.copyWith(localHighResPath: Value(localPath));
        });
      }
    } catch (e) {
      debugPrint('Viewer: Download failed for ${photo.fileName}: $e');
    } finally {
      if (mounted) setState(() => _isDownloading[photo.id] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.photos[_currentIndex];
    final dateStr = DateFormat('d MMMM yyyy', 'nl_NL').format(currentPhoto.dateTaken);
    final timeStr = DateFormat('HH:mm').format(currentPhoto.dateTaken);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showUI = !_showUI),
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (context, index) {
                final photo = widget.photos[index];
                final highResFile = photo.localHighResPath != null ? File(photo.localHighResPath!) : null;
                final thumbFile = photo.localThumbnailPath != null ? File(photo.localThumbnailPath!) : null;

                return PhotoViewGalleryPageOptions.customChild(
                  child: photo.mediaType == 'video'
                      ? VideoPlayerWidget(
                          videoPath: photo.localHighResPath,
                          thumbnailPath: photo.localThumbnailPath,
                          isDownloading: _isDownloading[photo.id] == true,
                          onPlayStateChanged: (isPlaying) {
                            if (isPlaying && _showUI) {
                              setState(() => _showUI = false);
                            }
                          },
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            if (thumbFile != null && thumbFile.existsSync())
                              Image.file(
                                thumbFile,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                gaplessPlayback: true,
                              ),
                            if (highResFile != null && highResFile.existsSync())
                              Image.file(
                                highResFile,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                gaplessPlayback: true,
                              ),
                            if (_isDownloading[photo.id] == true)
                              const Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
                                ),
                              ),
                          ],
                        ),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes: PhotoViewHeroAttributes(tag: photo.id),
                );
              },
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              itemCount: widget.photos.length,
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _downloadHighRes(index);
                _downloadHighRes(index + 1);
                _downloadHighRes(index - 1);
              },
            ),
          ),

          if (_showUI)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$dateStr om $timeStr',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (currentPhoto.locationName != null && currentPhoto.locationName!.isNotEmpty)
                            Text(
                              currentPhoto.locationName!,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        currentPhoto.isFavorite ? Icons.star : Icons.star_border,
                        color: currentPhoto.isFavorite ? Colors.yellow : Colors.white,
                      ),
                      onPressed: () => _toggleFavorite(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => _showExifInfo(),
                    ),
                  ],
                ),
              ),
            ),

          if (_showUI)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFooterIcon(Icons.share_outlined, 'Delen', () => _sharePhoto(currentPhoto)),
                      _buildFooterIcon(Icons.edit_outlined, 'Bewerken', () => _editPhoto(currentPhoto)),
                      _buildFooterIcon(Icons.add_to_photos_outlined, 'Album', () => _addToAlbum(currentPhoto)),
                      _buildFooterIcon(Icons.delete_outline, 'Prullenbak', () => _deletePhoto(currentPhoto)),
                    ],
                  ),
                ),
              ),
            ),

          if (_isDownloading[widget.photos[_currentIndex].id] == true && _showUI)
            const Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterIcon(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 28),
          onPressed: onTap,
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  void _toggleFavorite() async {
    final photo = widget.photos[_currentIndex];
    final newState = !photo.isFavorite;
    
    final db = AppDatabase();
    await db.toggleFavorite(photo.id, newState);
    
    setState(() {
      widget.photos[_currentIndex] = photo.copyWith(isFavorite: newState);
    });
  }

  Future<void> _sharePhoto(Photo photo) async {
    final path = photo.localHighResPath ?? photo.localThumbnailPath;
    if (path != null && File(path).existsSync()) {
      await Share.shareXFiles([XFile(path)], text: photo.fileName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto wordt nog gedownload...')));
    }
  }

  Future<void> _editPhoto(Photo photo) async {
    final path = photo.localHighResPath ?? photo.localThumbnailPath;
    if (path != null && File(path).existsSync()) {
      await OpenFilex.open(path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto wordt nog gedownload...')));
    }
  }

  Future<void> _addToAlbum(Photo photo) async {
    final db = AppDatabase();
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
                _createNewAlbum(photo);
              },
            ),
            const Divider(),
            ...albums.map((album) => ListTile(
              leading: const Icon(Icons.photo_album),
              title: Text(album.name),
              onTap: () async {
                await db.addPhotoToAlbum(album.id, photo.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Toegevoegd aan ${album.name}')));
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _createNewAlbum(Photo photo) async {
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
      final db = AppDatabase();
      final albumId = await db.createAlbum(result, coverPhotoId: photo.id);
      await db.addPhotoToAlbum(albumId, photo.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Album "$result" gemaakt')));
      }
    }
  }

  Future<void> _deletePhoto(Photo photo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verwijderen?'),
        content: const Text('Weet je zeker dat je deze foto wilt verwijderen uit de gallerij?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuleren')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verwijderen', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final db = AppDatabase();
      await (db.delete(db.photos)..where((t) => t.id.equals(photo.id))).go();
      
      if (photo.localHighResPath != null) File(photo.localHighResPath!).delete().catchError((_) {});
      if (photo.localThumbnailPath != null) File(photo.localThumbnailPath!).delete().catchError((_) {});

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _showExifInfo() {
    final photo = widget.photos[_currentIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Informatie', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.file_present),
                title: const Text('Bestandsnaam'),
                subtitle: Text(photo.fileName),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Datum genomen'),
                subtitle: Text(DateFormat('d MMMM yyyy HH:mm', 'nl_NL').format(photo.dateTaken)),
              ),
              if (photo.latitude != null && photo.longitude != null)
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Coördinaten'),
                  subtitle: Text('${photo.latitude}, ${photo.longitude}'),
                ),
              if (photo.locationName != null)
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Locatie'),
                  subtitle: Text(photo.locationName!),
                ),
              if (photo.latitude != null && photo.longitude != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Builder(
                        builder: (context) {
                          try {
                            return GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(photo.latitude!, photo.longitude!),
                                zoom: 12,
                              ),
                              markers: {
                                Marker(
                                  markerId: MarkerId(photo.id.toString()),
                                  position: LatLng(photo.latitude!, photo.longitude!),
                                ),
                              },
                              liteModeEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                            );
                          } catch (e) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(child: Text('Kaart niet beschikbaar')),
                            );
                          }
                        }
                      ),
                    ),
                  ),
                ),
              if (photo.cameraModel != null)
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  subtitle: Text(photo.cameraModel!),
                ),
              if (photo.lensModel != null)
                ListTile(
                  leading: const Icon(Icons.camera),
                  title: const Text('Lens'),
                  subtitle: Text(photo.lensModel!),
                ),
              if (photo.exposureTime != null || photo.fNumber != null || photo.iso != null || photo.focalLength != null)
                ListTile(
                  leading: const Icon(Icons.settings_brightness),
                  title: const Text('Instellingen'),
                  subtitle: Text([
                    if (photo.exposureTime != null) photo.exposureTime,
                    if (photo.fNumber != null) photo.fNumber,
                    if (photo.iso != null) 'ISO ${photo.iso}',
                    if (photo.focalLength != null) photo.focalLength,
                  ].join(' • ')),
                ),
              if (photo.flash != null)
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: const Text('Flits'),
                  subtitle: Text(photo.flash!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String? videoPath;
  final String? thumbnailPath;
  final bool isDownloading;
  final Function(bool)? onPlayStateChanged;

  const VideoPlayerWidget({
    super.key,
    this.videoPath,
    this.thumbnailPath,
    required this.isDownloading,
    this.onPlayStateChanged,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoPath != oldWidget.videoPath) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    if (widget.videoPath == null || !File(widget.videoPath!).existsSync()) return;

    await _disposePlayer();

    _videoPlayerController = VideoPlayerController.file(File(widget.videoPath!));
    await _videoPlayerController!.initialize();
    
    _videoPlayerController!.addListener(() {
      if (_videoPlayerController != null) {
        widget.onPlayStateChanged?.call(_videoPlayerController!.value.isPlaying);
      }
    });

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
    );

    if (mounted) setState(() {});
  }

  Future<void> _disposePlayer() async {
    _chewieController?.dispose();
    await _videoPlayerController?.dispose();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null && _videoPlayerController!.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.thumbnailPath != null && File(widget.thumbnailPath!).existsSync())
          Image.file(
            File(widget.thumbnailPath!),
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        const Icon(Icons.play_circle_outline, size: 80, color: Colors.white54),
        if (widget.isDownloading)
          const Positioned(
            bottom: 20,
            child: CircularProgressIndicator(color: Colors.white70),
          ),
      ],
    );
  }
}
