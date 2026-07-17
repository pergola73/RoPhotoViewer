import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kphoto/presentation/blocs/gallery_bloc.dart';
import 'package:kphoto/presentation/screens/gallery_screen.dart';

class InitialSyncScreen extends StatefulWidget {
  const InitialSyncScreen({super.key});

  @override
  State<InitialSyncScreen> createState() => _InitialSyncScreenState();
}

class _InitialSyncScreenState extends State<InitialSyncScreen> {
  @override
  void initState() {
    super.initState();
    // Start de grote sync zodra het scherm geladen is
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryBloc>().add(SyncWithKDrive());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GalleryBloc, GalleryState>(
      listener: (context, state) {
        if (state.isFirstSyncComplete) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const GalleryScreen()),
          );
        }
      },
      builder: (context, state) {
        final bool isScanning = state.syncPhase == SyncPhase.scanning;
        
        // We berekenen het percentage alleen tijdens het downloaden.
        // Tijdens scannen is het indeterminate (draaiend).
        double? progress;
        if (!isScanning && state.totalPhotoCount > 0) {
          progress = (state.processedCount / state.totalPhotoCount).clamp(0.0, 1.0);
        }
            
        return Scaffold(
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_download, size: 100, color: Colors.white),
                const SizedBox(height: 32),
                Text(
                  isScanning ? 'Bibliotheek scannen...' : 'Fotos ophalen...',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isScanning 
                    ? 'We inventariseren je kDrive mappen. Even geduld...' 
                    : 'De tijdlijn en previews worden nu binnengehaald.',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Progress Indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (progress != null)
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                          )
                        else
                          const Icon(Icons.search, color: Colors.white, size: 40),
                        const SizedBox(height: 4),
                        Text(
                          '${state.processedCount} fotos',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                if (state.estimatedTimeRemaining != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Nog ongeveer ${state.estimatedTimeRemaining}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                
                const SizedBox(height: 24),
                const Icon(Icons.info_outline, color: Colors.white54, size: 20),
                const SizedBox(height: 8),
                const Text(
                  'Je kunt je telefoon gerust vergrendelen.\nHet proces gaat op de achtergrond door.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
