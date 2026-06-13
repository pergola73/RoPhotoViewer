import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ro_photo_viewer/core/database/app_database.dart';
import 'package:ro_photo_viewer/core/network/auth_repository.dart';
import 'package:ro_photo_viewer/core/network/kdrive_api_service.dart';
import 'package:ro_photo_viewer/core/services/ai_tagging_service.dart';
import 'package:ro_photo_viewer/presentation/blocs/gallery_bloc.dart';
import 'package:ro_photo_viewer/presentation/screens/gallery_screen.dart';
import 'package:ro_photo_viewer/presentation/screens/login_screen.dart';
import 'package:ro_photo_viewer/core/network/sync_engine.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('nl_NL', null);

  final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
  }
  
  final database = AppDatabase();
  final apiService = KDriveApiService();
  final authRepository = AuthRepository();
  final syncEngine = SyncEngine(apiService, database);
  final aiTaggingService = AITaggingService(database);
  
  final loggedIn = await authRepository.isLoggedIn();
  if (loggedIn) {
    final creds = await authRepository.getCredentials();
    try {
      await apiService.initialize(creds['token']!, creds['driveId']!);
    } catch (e) {
      debugPrint('API Auto-init failed: $e');
    }
  }

  // Start background tagging
  aiTaggingService.processPendingPhotos();

  runApp(MyApp(
    database: database,
    syncEngine: syncEngine,
    apiService: apiService,
    authRepository: authRepository,
    initialScreen: loggedIn ? const GalleryScreen() : LoginScreen(
      apiService: apiService,
      authRepository: authRepository,
    ),
  ));
}

class MyApp extends StatelessWidget {
  final AppDatabase database;
  final SyncEngine syncEngine;
  final KDriveApiService apiService;
  final AuthRepository authRepository;
  final Widget initialScreen;

  const MyApp({
    super.key, 
    required this.database,
    required this.syncEngine,
    required this.apiService,
    required this.authRepository,
    required this.initialScreen,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GalleryBloc(
            database, 
            syncEngine: syncEngine,
          )..add(LoadGallery()),
        ),
      ],
      child: MaterialApp(
        title: 'K-Photo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: initialScreen,
      ),
    );
  }
}
