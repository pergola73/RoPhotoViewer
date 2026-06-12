import 'package:flutter/material.dart';
import 'package:ro_photo_viewer/core/network/auth_repository.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ro_photo_viewer/presentation/screens/folder_browser_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCredentials();
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
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Instellingen Opslaan'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
