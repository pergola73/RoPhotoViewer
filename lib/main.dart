import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kphoto/core/database/app_database.dart';
import 'package:kphoto/core/network/auth_repository.dart';
import 'package:kphoto/core/network/kdrive_api_service.dart';
import 'package:kphoto/core/services/ai_tagging_service.dart';
import 'package:kphoto/presentation/blocs/gallery_bloc.dart';
import 'package:kphoto/core/network/sync_engine.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:kphoto/core/database/objectbox_manager.dart';
import 'package:kphoto/core/services/media_processor_service.dart';
import 'package:kphoto/core/services/vector_search_service.dart';
import 'package:kphoto/core/services/image_embedding_service.dart';

import 'package:kphoto/presentation/screens/firebase_login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(SyncTaskHandler());
}

class SyncTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('SyncTaskHandler: Foreground service gestart');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Wordt aangeroepen op basis van interval, we gebruiken liever onStart voor de main loop
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('SyncTaskHandler: Foreground service gestopt (Timeout: $isTimeout)');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterForegroundTask.initCommunicationPort();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('nl_NL', null);

  final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
  }
  
  final database = AppDatabase();
  final objectBox = await ObjectBoxManager.create();
  
  final apiService = KDriveApiService();
  final authRepository = AuthRepository();
  
  final mediaProcessor = MediaProcessorService(objectBox);
  final vectorSearch = VectorSearchService(objectBox);
  
  final syncEngine = SyncEngine(apiService, database, mediaProcessor: mediaProcessor);
  
  // Trigger AI Model download/init in de achtergrond
  unawaited(ImageEmbeddingService().init());

  final aiTaggingService = AITaggingService(database, apiService);
  
  final loggedIn = await authRepository.isLoggedIn();
  if (loggedIn) {
    final creds = await authRepository.getCredentials();
    try {
      await apiService.initialize(creds['token']!, creds['driveId']!);
    } catch (e) {
      debugPrint('API Auto-init failed: $e');
    }
  }

  runApp(MyApp(
    database: database,
    objectBox: objectBox,
    syncEngine: syncEngine,
    apiService: apiService,
    authRepository: authRepository,
    vectorSearch: vectorSearch,
    mediaProcessor: mediaProcessor,
  ));
}

class MyApp extends StatelessWidget {
  final AppDatabase database;
  final ObjectBoxManager objectBox;
  final SyncEngine syncEngine;
  final KDriveApiService apiService;
  final AuthRepository authRepository;
  final VectorSearchService vectorSearch;
  final MediaProcessorService mediaProcessor;

  const MyApp({
    super.key, 
    required this.database,
    required this.objectBox,
    required this.syncEngine,
    required this.apiService,
    required this.authRepository,
    required this.vectorSearch,
    required this.mediaProcessor,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GalleryBloc(
            database, 
            syncEngine: syncEngine,
            vectorSearch: vectorSearch,
            mediaProcessor: mediaProcessor,
          )..add(LoadGallery()),
        ),
      ],
      child: MaterialApp(
        title: 'K-Photo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const FirebaseLoginScreen(),
      ),
    );
  }
}
