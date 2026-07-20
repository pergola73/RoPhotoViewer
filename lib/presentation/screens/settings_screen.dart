import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kphoto/core/network/auth_repository.dart';
import 'package:kphoto/core/database/app_database.dart';
import 'package:kphoto/presentation/blocs/gallery_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import 'package:kphoto/core/network/kdrive_api_service.dart';
import 'package:kphoto/presentation/screens/folder_browser_screen.dart';
import 'package:kphoto/presentation/screens/firebase_login_screen.dart';
import 'package:kphoto/core/services/ai_tagging_service.dart';
import 'package:kphoto/core/services/biometric_service.dart';
import 'package:kphoto/presentation/screens/trash_screen.dart';
import 'package:kphoto/presentation/screens/connect_kdrive_screen.dart';
import 'package:kphoto/core/services/image_embedding_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthRepository();
  final _tokenController = TextEditingController();
  final _driveIdController = TextEditingController();
  final _urlController = TextEditingController();
  List<String> _folderIds = [];
  Map<String, int> _folderPhotoCounts = {};
  bool _isLoading = true;
  double _aiDownloadProgress = 0.0;
  bool _isAiDownloading = false;
  String _version = '';
  String _buildNumber = '';
  bool _useBiometrics = false;
  bool _isBiometricsAvailable = false;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _loadPackageInfo();
    _checkBiometricsSupport();
  }

  Future<void> _checkBiometricsSupport() async {
    final bioService = BiometricService();
    final isAvailable = await bioService.canCheckBiometrics();
    final enabled = await _auth.isBiometricsEnabled();
    if (mounted) {
      setState(() {
        _isBiometricsAvailable = isAvailable;
        _useBiometrics = enabled;
      });
    }
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  Future<void> _loadCredentials() async {
    final creds = await _auth.getCredentials();
    final ids = await _auth.getFolderIds();
    final db = AppDatabase();
    Map<String, int> counts = {};
    for (var id in ids) {
      counts[id] = await db.getPhotoCountForFolder(id);
    }
    if (mounted) {
      setState(() {
        _tokenController.text = creds['token'] ?? '';
        _driveIdController.text = creds['driveId'] ?? '';
        _folderIds = ids;
        _folderPhotoCounts = counts;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final token = _tokenController.text.trim();
    final driveId = _driveIdController.text.trim();

    await _auth.saveCredentials(
      token: token,
      driveId: driveId,
      folderId: _folderIds.isNotEmpty ? _folderIds.first : '',
    );
    await _auth.saveFolderIds(_folderIds);
    
    if (token.isNotEmpty && driveId.isNotEmpty) {
      await KDriveApiService().initialize(token, driveId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instellingen opgeslagen')),
      );
      Navigator.pop(context);
    }
  }

  void _addFolderFromUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.contains('files')) {
      final idx = uri.pathSegments.indexOf('files');
      if (idx + 1 < uri.pathSegments.length) {
        final id = uri.pathSegments[idx + 1];
        if (!_folderIds.contains(id)) {
          setState(() {
            _folderIds.add(id);
            _urlController.clear();
          });
        }
      }
    } else if (RegExp(r'^\d+$').hasMatch(url)) {
      if (!_folderIds.contains(url)) {
        setState(() {
          _folderIds.add(url);
          _urlController.clear();
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ongeldige URL of ID')));
    }
  }

  Future<void> _browseFolders() async {
    final driveId = _driveIdController.text.trim();
    if (driveId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vul eerst een Drive ID in')));
      return;
    }

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => FolderBrowserScreen(
          driveId: driveId,
          initialFolderId: _folderIds.isNotEmpty ? _folderIds.first : '0',
        ),
      ),
    );

    if (result != null && !_folderIds.contains(result)) {
      setState(() => _folderIds.add(result));
    }
  }

  void _shareApp() {
    Share.share('Check out K-Photo! Een privacy-vriendelijke foto galerij voor kDrive.', subject: 'K-Photo App');
  }

  Future<void> _clearCache() async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory('${dir.path}/view_cache');
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache geleegd')));
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'db.sqlite'));
      
      if (!await dbFile.exists()) {
        throw Exception('Database bestand niet gevonden');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Niet ingelogd bij Firebase');

      debugPrint('Firebase Storage: Starten backup naar bucket: ${FirebaseStorage.instance.bucket}');

      // Firebase Storage Backup met specifiekere metadata en error handling
      final storageRef = FirebaseStorage.instance.ref().child('backups/${user.uid}/index_backup.sqlite');
      
      final uploadTask = storageRef.putFile(
        dbFile,
        SettableMetadata(contentType: 'application/x-sqlite3'),
      );

      // Monitor voortgang voor extra debugging
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        debugPrint('Firebase Storage: Status ${snapshot.state} (${snapshot.bytesTransferred}/${snapshot.totalBytes})');
      });

      await uploadTask;
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Index backup succesvol opgeslagen in Firebase Cloud')));
    } catch (e) {
      debugPrint('Firebase Storage FOUT: $e');
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('404')) {
          errorMsg = 'Firebase Storage bucket niet gevonden. Controleer of Storage is geactiveerd in de Firebase Console.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cloud backup mislukt: $errorMsg')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportLocalBackup() async {
    setState(() => _isLoading = true);
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'db.sqlite'));
      
      // Zoek de openbare download map
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir != null && await dbFile.exists()) {
        final exportPath = p.join(downloadsDir.path, 'kphoto_backup_${DateTime.now().millisecondsSinceEpoch}.sqlite');
        await dbFile.copy(exportPath);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bestand opgeslagen in Downloads map:\n${p.basename(exportPath)}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lokaal opslaan mislukt: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Index herstellen uit Cloud?'),
        content: const Text('Dit herstelt je tijdlijn vanuit de Firebase Cloud backup.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULEREN')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('HERSTELLEN')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbFile = File(p.join(dbFolder.path, 'db.sqlite'));
        final tmpFile = File(p.join(dbFolder.path, 'db_restore.tmp'));
        
        final storageRef = FirebaseStorage.instance.ref().child('backups/${user.uid}/index_backup.sqlite');
        
        // Download eerst naar een tijdelijk bestand
        await storageRef.writeToFile(tmpFile);
        
        if (await tmpFile.exists()) {
          // Vervang het echte database bestand
          await tmpFile.copy(dbFile.path);
          await tmpFile.delete();
          
          if (mounted) {
             showDialog(
               context: context,
               barrierDismissible: false,
               builder: (context) => AlertDialog(
                 title: const Text('Herstel voltooid'),
                 content: const Text('De database is succesvol hersteld. De app wordt nu afgesloten om de wijzigingen te laden.'),
                 actions: [
                   ElevatedButton(
                     onPressed: () => exit(0), 
                     child: const Text('AFSLUITEN'),
                   ),
                 ],
               ),
             );
          }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Herstel mislukt: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, bool>> _checkAiModels() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final modelPath = p.join(docsDir.path, 'image_embedder.tflite');
    return {
      'model': File(modelPath).existsSync(),
    };
  }

  Widget _buildStatusTile(String title, bool exists) {
    if (_isAiDownloading) {
      return ListTile(
        leading: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        title: Text(title),
        subtitle: Text('Downloaden AI module: ${(_aiDownloadProgress * 100).toInt()}%'),
      );
    }

    return ListTile(
      leading: Icon(exists ? Icons.check_circle : Icons.downloading, 
                   color: exists ? Colors.green : Colors.orange),
      title: Text(title),
      subtitle: Text(exists ? 'Klaar voor gebruik (Lokaal)' : 'Tik om model te installeren'),
      trailing: exists 
        ? IconButton(
            icon: const Icon(Icons.play_circle_outline, color: Colors.purple),
            onPressed: () {
              context.read<GalleryBloc>().add(const StartAiScan(forceAll: true));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Analyse gestart op de achtergrond...')));
              Navigator.pop(context);
            },
            tooltip: 'Start AI Analyse',
          )
        : IconButton(
            icon: const Icon(Icons.file_download, color: Colors.blue),
            onPressed: () async {
              setState(() {
                _isAiDownloading = true;
                _aiDownloadProgress = 0.0;
              });
              try {
                await ImageEmbeddingService().init(onProgress: (p) {
                  setState(() => _aiDownloadProgress = p);
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fout bij download: $e')));
              } finally {
                setState(() => _isAiDownloading = false);
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instellingen')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('API Configuratie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tokenController,
                    obscureText: _obscureToken,
                    decoration: InputDecoration(
                      labelText: 'API Token', 
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureToken ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureToken = !_obscureToken),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _driveIdController,
                    decoration: const InputDecoration(labelText: 'Drive ID', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('AI & ZOEKMACHINE STATUS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 8),
                  FutureBuilder<Map<String, bool>>(
                    future: _checkAiModels(),
                    builder: (context, snapshot) {
                      final exists = snapshot.data?['model'] ?? false;
                      return _buildStatusTile('Google AI Engine (MobileNet-v3)', exists);
                    },
                  ),
                  const Divider(),

                  const Text('Synchroniseer Mappen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(controller: _urlController, decoration: const InputDecoration(hintText: 'Plak kDrive URL of ID', border: OutlineInputBorder())),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(onPressed: _addFolderFromUrl, icon: const Icon(Icons.add)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: _browseFolders, icon: const Icon(Icons.folder_open), label: const Text('Bladeren in kDrive')),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _folderIds.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final id = _folderIds[index];
                        final count = _folderPhotoCounts[id] ?? 0;
                        return ListTile(
                          title: Text('Map ID: $id'),
                          subtitle: Text('$count fotos gesynchroniseerd'),
                          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _folderIds.removeAt(index))),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text('Beveiliging & Opslag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (_isBiometricsAvailable)
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint),
                      title: const Text('Biometrisch inloggen'),
                      value: _useBiometrics,
                      onChanged: (bool value) async {
                        await _auth.setBiometricsEnabled(value);
                        setState(() => _useBiometrics = value);
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Prullenbak'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrashScreen())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services),
                    title: const Text('Cache legen'),
                    onTap: _clearCache,
                  ),
                  const Divider(),
                  const Text('Index Cloud Backup (Metadata)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Veilig en betrouwbaar opslaan in de Firebase Cloud.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _createBackup,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('CLOUD BACKUP'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _restoreBackup,
                          icon: const Icon(Icons.cloud_download),
                          label: const Text('HERSTELLEN'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Lokaal exporteren', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Sla de database op in de Downloads map van je telefoon.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _exportLocalBackup,
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('OPSLAAN IN DOWNLOADS'),
                    ),
                  ),

                  const SizedBox(height: 32),
                  ListTile(
                    leading: const Icon(Icons.refresh, color: Colors.blue),
                    title: const Text('kDrive opnieuw koppelen'),
                    onTap: () async {
                      await _auth.disconnectKDrive();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const ConnectKDriveScreen()), (route) => false);
                      }
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  BlocBuilder<GalleryBloc, GalleryState>(
                    builder: (context, state) {
                      return Center(
                        child: Column(
                          children: [
                            Text('Totaal: ${state.totalPhotoCount} fotos', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text('Versie $_version ($_buildNumber)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)), child: const Text('Opslaan')),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      await _auth.logout();
                      if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const FirebaseLoginScreen()), (route) => false);
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Uitloggen', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
