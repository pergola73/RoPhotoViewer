import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kphoto/core/network/auth_repository.dart';
import 'package:kphoto/presentation/blocs/gallery_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

import 'package:kphoto/core/network/kdrive_api_service.dart';
import 'package:kphoto/presentation/screens/folder_browser_screen.dart';
import 'package:kphoto/presentation/screens/firebase_login_screen.dart';
import 'package:kphoto/core/services/ai_tagging_service.dart';
import 'package:kphoto/core/services/biometric_service.dart';
import 'package:kphoto/presentation/screens/trash_screen.dart';
import 'package:kphoto/presentation/screens/connect_kdrive_screen.dart';

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
  bool _isLoading = true;
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
    if (mounted) {
      setState(() {
        _tokenController.text = creds['token'] ?? '';
        _driveIdController.text = creds['driveId'] ?? '';
        _folderIds = ids;
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

  Future<Map<String, bool>> _checkAiModels() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final modelPath = p.join(docsDir.path, 'image_embedder.tflite');
    return {
      'model': File(modelPath).existsSync(),
    };
  }

  Widget _buildStatusTile(String title, bool exists) {
    return ListTile(
      leading: Icon(exists ? Icons.check_circle : Icons.downloading, 
                   color: exists ? Colors.green : Colors.orange),
      title: Text(title),
      subtitle: Text(exists ? 'Klaar voor gebruik (Lokaal)' : 'Wordt gedownload bij eerste gebruik'),
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
                        return ListTile(
                          title: Text('Map ID: $id'),
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
