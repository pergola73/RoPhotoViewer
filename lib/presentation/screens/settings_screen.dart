import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:k_photo/core/network/auth_repository.dart';
import 'package:k_photo/presentation/blocs/gallery_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

import 'package:k_photo/presentation/screens/folder_browser_screen.dart';
import 'package:k_photo/presentation/screens/firebase_login_screen.dart';
import 'package:k_photo/core/services/ai_tagging_service.dart';
import 'package:k_photo/core/services/biometric_service.dart';

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
    await _auth.saveCredentials(
      token: _tokenController.text.trim(),
      driveId: _driveIdController.text.trim(),
      folderId: _folderIds.isNotEmpty ? _folderIds.first : '',
    );
    await _auth.saveFolderIds(_folderIds);
    
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

    // Extract ID from URL like .../files/3377
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
    } else {
      // If it's just a number, add it
      if (RegExp(r'^\d+$').hasMatch(url)) {
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
    Share.share(
      'Check out K-Photo! Een privacy-vriendelijke foto galerij voor kDrive. Download het hier: [LINK_NAAR_JE_APP]',
      subject: 'K-Photo App',
    );
  }

  Future<void> _clearCache() async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory('${dir.path}/view_cache');
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache met grote foto\'s is geleegd')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache is al leeg')),
        );
      }
    }
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
                    decoration: const InputDecoration(labelText: 'API Token', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _driveIdController,
                    decoration: const InputDecoration(labelText: 'Drive ID', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  const Text('Synchroniseer Mappen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            hintText: 'Plak kDrive URL of map ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addFolderFromUrl,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _browseFolders,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Bladeren in kDrive'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _folderIds.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final id = _folderIds[index];
                        return ListTile(
                          title: Text('Map ID: $id'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => setState(() => _folderIds.removeAt(index)),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_folderIds.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Geen mappen geselecteerd.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ),
                  const SizedBox(height: 32),
                  const Text('Opslagbeheer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services),
                    title: const Text('Cache legen'),
                    subtitle: const Text('Verwijder lokaal gedownloade grote foto\'s'),
                    onTap: _clearCache,
                    tileColor: Colors.orange.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Beveiliging', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (_isBiometricsAvailable)
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint),
                      title: const Text('Biometrisch inloggen'),
                      subtitle: const Text('Gebruik FaceID of vingerafdruk'),
                      value: _useBiometrics,
                      onChanged: (bool value) async {
                        await _auth.setBiometricsEnabled(value);
                        setState(() => _useBiometrics = value);
                      },
                    )
                  else
                    const ListTile(
                      leading: Icon(Icons.fingerprint, color: Colors.grey),
                      title: Text('Biometrie niet beschikbaar', style: TextStyle(color: Colors.grey)),
                      subtitle: Text('Zorg dat je FaceID of een vingerafdruk hebt ingesteld op je toestel.'),
                    ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: const Text('AI Tags opnieuw scannen'),
                    subtitle: const Text('Werk je zoekindex bij met de nieuwste termen'),
                    onTap: () async {
                      if (!mounted) return;
                      final galleryBloc = BlocProvider.of<GalleryBloc>(context);
                      final db = galleryBloc.db;
                      // Haal API direct uit de syncEngine van de Bloc
                      final api = galleryBloc.syncEngine?.apiService;
                      
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI re-scan gestart op de achtergrond...')));
                      
                      final aiService = AITaggingService(db, api);
                      await aiService.processPendingPhotos(forceAll: true);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI re-scan voltooid!')));
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text('App Delen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.share),
                    title: const Text('Deel K-Photo met vrienden'),
                    subtitle: const Text('Stuur een downloadlink naar anderen'),
                    onTap: _shareApp,
                    tileColor: Colors.blue.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  const SizedBox(height: 32),
                  if (_version.isNotEmpty)
                    Center(
                      child: Text(
                        'Versie $_version ($_buildNumber)',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Instellingen Opslaan'),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () async {
                      await _auth.logout();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const FirebaseLoginScreen()),
                          (route) => false,
                        );
                      }
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
