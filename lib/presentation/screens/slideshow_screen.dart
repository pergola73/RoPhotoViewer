import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kphoto/core/database/app_database.dart';
import 'package:kphoto/core/network/kdrive_api_service.dart';
import 'package:kphoto/core/network/auth_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kphoto/presentation/blocs/gallery_bloc.dart';

class SlideshowScreen extends StatefulWidget {
  final List<Photo> photos;
  final bool randomize;

  const SlideshowScreen({
    super.key,
    required this.photos,
    this.randomize = false,
  });

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  late List<Photo> _playlist;
  int _currentIndex = 0;
  Timer? _timer;
  bool _isPlaying = true;
  bool _showUI = false;
  final int _preloadCount = 3;
  final Map<int, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
    // Verberg statusbalk voor volledige focus
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _playlist = List.from(widget.photos);
    if (widget.randomize) {
      _playlist.shuffle(Random());
    }
    
    _startSlideshow();
    _preloadNext();
  }

  @override
  void dispose() {
    // Herstel statusbalk bij verlaten
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _timer?.cancel();
    super.dispose();
  }

  void _startSlideshow() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isPlaying && mounted) {
        _nextPhoto();
      }
    });
  }

  void _nextPhoto() {
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    });
    _preloadNext();
  }

  void _previousPhoto() {
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    });
    _preloadNext();
  }

  Future<void> _preloadNext() async {
    for (int i = 0; i <= _preloadCount; i++) {
      final index = (_currentIndex + i) % _playlist.length;
      _downloadHighRes(index);
    }
  }

  Future<void> _downloadHighRes(int index) async {
    final photo = _playlist[index];

    if (photo.mediaType != 'image') return;
    if (photo.localHighResPath != null && File(photo.localHighResPath!).existsSync()) return;
    if (_isDownloading[photo.id] == true) return;

    _isDownloading[photo.id] = true;

    try {
      final auth = AuthRepository();
      final creds = await auth.getCredentials();
      final api = KDriveApiService();
      await api.initialize(creds['token']!, creds['driveId']!);

      final dir = await getTemporaryDirectory();
      final photosDir = Directory(p.join(dir.path, 'view_cache'));
      if (!photosDir.existsSync()) photosDir.createSync(recursive: true);
      
      final localPath = p.join(photosDir.path, '${photo.id}_${photo.fileName}');
      await api.downloadFile(photo.kdrivePath, localPath);

      if (File(localPath).existsSync() && mounted) {
        final db = AppDatabase();
        await (db.update(db.photos)..where((t) => t.id.equals(photo.id))).write(
          PhotosCompanion(localHighResPath: Value(localPath)),
        );
        
        setState(() {
          _playlist[index] = photo.copyWith(localHighResPath: Value(localPath));
        });
      }
    } catch (e) {
      debugPrint('Slideshow: Download failed for ${photo.fileName}: $e');
    } finally {
      _isDownloading[photo.id] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_playlist.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Geen foto\'s beschikbaar', style: TextStyle(color: Colors.white))));
    }

    final currentPhoto = _playlist[_currentIndex];
    final highResFile = currentPhoto.localHighResPath != null ? File(currentPhoto.localHighResPath!) : null;
    final thumbFile = currentPhoto.localThumbnailPath != null ? File(currentPhoto.localThumbnailPath!) : null;
    final isDownloading = _isDownloading[currentPhoto.id] == true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // De Foto met cross-fade animatie
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
            child: Container(
              key: ValueKey(currentPhoto.id),
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbFile != null && thumbFile.existsSync())
                    Image.file(
                      thumbFile,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  if (highResFile != null && highResFile.existsSync())
                    Image.file(
                      highResFile,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                ],
              ),
            ),
          ),

          // Invisible interaction layer
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _showUI = !_showUI;
                });
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  _previousPhoto();
                } else if (details.primaryVelocity! < 0) {
                  _nextPhoto();
                }
              },
            ),
          ),

          // Top Bar (Kruisje) - Alleen zichtbaar na tap
          AnimatedOpacity(
            opacity: _showUI ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_showUI,
              child: Positioned(
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
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                        onPressed: () => setState(() => _isPlaying = !_isPlaying),
                      ),
                      if (isDownloading)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Bar (Locatie) - Alleen zichtbaar na tap
          AnimatedOpacity(
            opacity: _showUI ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_showUI,
              child: Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Text(
                      currentPhoto.locationName ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1))],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
