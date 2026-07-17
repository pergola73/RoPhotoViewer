import 'package:flutter/material.dart';
import 'package:kphoto/core/network/auth_repository.dart';
import 'package:kphoto/core/network/kdrive_api_service.dart';
import 'package:kphoto/presentation/screens/gallery_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

class ConnectKDriveScreen extends StatefulWidget {
  const ConnectKDriveScreen({super.key});

  @override
  State<ConnectKDriveScreen> createState() => _ConnectKDriveScreenState();
}

class _ConnectKDriveScreenState extends State<ConnectKDriveScreen> {
  final _auth = AuthRepository();
  final _api = KDriveApiService();
  final _tokenController = TextEditingController();
  int _step = 0; // 0: Token, 1: Drives, 2: Folders
  bool _isBusy = false;
  List<Map<String, dynamic>> _drives = [];
  String? _selectedDriveId;
  List<dynamic> _currentFolders = [];
  final Set<String> _selectedFolderIds = {};
  final _driveIdController = TextEditingController();
  final _folderIdController = TextEditingController();

  void _validateToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      // Gebruik de nieuwe setToken methode
      _api.setToken(token);
      final drives = await _api.getAvailableDrives();
      
      if (drives.isEmpty) {
        throw Exception('Geen drives gevonden');
      }

      setState(() {
        _drives = drives;
        _step = 1;
        _isBusy = false;
        if (_drives.length == 1) {
          _selectDrive(_drives.first['id'].toString());
        }
      });
    } catch (e) {
      String errorMsg = 'Fout bij verbinden.';
      if (e is DioException) {
        if (e.response?.statusCode == 401) errorMsg = 'Token is ongeldig of verlopen.';
        else if (e.response?.statusCode == 403) errorMsg = 'Token heeft geen rechten voor kDrive (scope kdrive mist).';
        else errorMsg = 'Server fout: ${e.response?.statusCode}';
      }
      
      debugPrint('Validation error: $e');
      setState(() => _isBusy = false);
      if (mounted) {
        // Toon de fout, maar geef direct de optie om handmatig verder te gaan
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Automatische detectie mislukt'),
            content: Text('We konden je drives niet automatisch vinden ($errorMsg).\n\nWil je de Drive ID en Map ID handmatig invullen?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nogmaals proberen')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _step = 3);
                },
                child: const Text('Handmatig invullen'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _manualEntry(String driveId, String folderId) async {
    final token = _tokenController.text.trim();
    if (token.isEmpty || driveId.isEmpty || folderId.isEmpty) return;

    await _auth.saveCredentials(token: token, driveId: driveId, folderId: folderId);
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const GalleryScreen()));
    }
  }

  void _selectDrive(String driveId) async {
    setState(() {
      _selectedDriveId = driveId;
      _isBusy = true;
    });

    final token = _tokenController.text.trim();
    await _api.initialize(token, driveId);
    
    // Haal de top-level mappen op
    try {
      final stream = _api.getChildrenStream('0');
      final firstBatch = await stream.first;

      setState(() {
        _currentFolders = firstBatch.where((i) => i['type'] == 'dir' || i['type'] == 'folder' || i['type'] == 'node_dir').toList();
        _step = 2;
        _isBusy = false;
      });
    } catch (e) {
      setState(() => _isBusy = false);
    }
  }

  void _finish() async {
    if (_selectedDriveId == null || _selectedFolderIds.isEmpty) return;

    await _auth.saveCredentials(
      token: _tokenController.text.trim(),
      driveId: _selectedDriveId!,
      folderId: _selectedFolderIds.first,
    );
    await _auth.saveFolderIds(_selectedFolderIds.toList());

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GalleryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest van de build blijft gelijk, ik pas de welcome step aan)
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.cloud_sync, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'K-Photo',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_step == 0) _buildWelcomeStep(),
                    if (_step == 1) _buildDriveStep(),
                    if (_step == 2) _buildFolderStep(),
                    if (_step == 3) _buildManualStep(),
                    if (_isBusy) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      children: [
        const Text(
          'Koppel je kDrive',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Stap 1: Maak een API-token aan.\nBELANGRIJK: Kies voor "Default Application" bij het aanmaken.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        const Text(
          'Kies daarna voor "kDrive" (Read-only of Full access).',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _tokenController,
          decoration: const InputDecoration(
            labelText: 'API Token',
            hintText: 'Plak hier je kDrive API token',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            final url = Uri.parse('https://manager.infomaniak.com/v3/ng/accounts/token/list');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Maak een token aan bij Infomaniak'),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: (_isBusy || _tokenController.text.isEmpty) ? null : _validateToken,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Verder naar Drive selectie', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _step = 3),
          child: const Text('Ik heb al een Drive ID en Map ID', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildDriveStep() {
    return Column(
      children: [
        const Text(
          'Kies je kDrive',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._drives.map((drive) => ListTile(
          leading: const Icon(Icons.storage, color: Colors.blue),
          title: Text(drive['name'] ?? 'kDrive'),
          subtitle: Text('ID: ${drive['id']}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _selectDrive(drive['id'].toString()),
        )),
      ],
    );
  }

  Widget _buildFolderStep() {
    return Column(
      children: [
        const Text(
          'Selecteer fotomappen',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Kies de mappen die we moeten scannen.', style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: _currentFolders.length,
            itemBuilder: (context, index) {
              final folder = _currentFolders[index];
              final id = folder['id'].toString();
              final isSelected = _selectedFolderIds.contains(id);
              return CheckboxListTile(
                title: Text(folder['name'] ?? 'Onbekend'),
                secondary: const Icon(Icons.folder, color: Colors.amber),
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) _selectedFolderIds.add(id);
                    else _selectedFolderIds.remove(id);
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _selectedFolderIds.isEmpty ? null : _finish,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Start K-Photo'),
        ),
      ],
    );
  }

  Widget _buildManualStep() {
    return Column(
      children: [
        const Text('Handmatige configuratie', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: _driveIdController,
          decoration: const InputDecoration(labelText: 'Drive ID', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _folderIdController,
          decoration: const InputDecoration(labelText: 'Fotomap ID (bijv. 0 voor root)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => _manualEntry(_driveIdController.text.trim(), _folderIdController.text.trim()),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          child: const Text('Opslaan en Starten'),
        ),
        TextButton(onPressed: () => setState(() => _step = 0), child: const Text('Terug naar Token')),
      ],
    );
  }
}
