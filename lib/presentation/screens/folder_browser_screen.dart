import 'package:flutter/material.dart';
import 'package:kphoto/core/network/kdrive_api_service.dart';

class FolderBrowserScreen extends StatefulWidget {
  final String driveId;
  final String initialFolderId;

  const FolderBrowserScreen({
    super.key,
    required this.driveId,
    required this.initialFolderId,
  });

  @override
  State<FolderBrowserScreen> createState() => _FolderBrowserScreenState();
}

class _FolderBrowserScreenState extends State<FolderBrowserScreen> {
  final KDriveApiService _api = KDriveApiService();
  final List<String> _history = [];
  late String _currentFolderId;
  bool _isLoading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _currentFolderId = widget.initialFolderId;
    _loadFolder(_currentFolderId);
  }

  Future<void> _loadFolder(String folderId) async {
    setState(() => _isLoading = true);
    try {
      // Use the stream but just get the first batch for browsing
      final stream = _api.getChildrenStream(folderId);
      final List<dynamic> allItems = [];
      await for (final batch in stream) {
        allItems.addAll(batch);
        // For browsing we don't need thousands of items, just folders
        if (allItems.length > 200) break; 
      }
      
      if (mounted) {
        setState(() {
          _currentFolderId = folderId;
          _items = allItems.where((item) {
            final type = item['type']?.toString();
            final mime = item['mime_type']?.toString();
            return type == 'dir' || type == 'folder' || mime == 'application/x-directory' || type == 'node_dir';
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fout bij laden map: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateIn(String folderId) {
    _history.add(_currentFolderId);
    _loadFolder(folderId);
  }

  void _navigateBack() {
    if (_history.isNotEmpty) {
      final prev = _history.removeLast();
      _loadFolder(prev);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selecteer map ($_currentFolderId)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBack,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Geen submappen gevonden.'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final name = item['name'] ?? 'Onbekende map';
                    final id = (item['id'] ?? item['file_id'] ?? item['node_id'])?.toString();

                    return ListTile(
                      leading: const Icon(Icons.folder, color: Colors.amber),
                      title: Text(name),
                      subtitle: Text('ID: $id'),
                      onTap: () => _navigateIn(id!),
                      trailing: IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        onPressed: () => Navigator.pop(context, id),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, _currentFolderId),
        label: const Text('Kies huidige map'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
