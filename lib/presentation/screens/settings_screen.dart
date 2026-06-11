import 'package:flutter/material.dart';
import 'package:ro_photo_viewer/core/network/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ro_photo_viewer/presentation/blocs/gallery_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthRepository();
  final _tokenController = TextEditingController();
  final _driveIdController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final creds = await _auth.getCredentials();
    if (mounted) {
      setState(() {
        _tokenController.text = creds['token'] ?? '';
        _driveIdController.text = creds['driveId'] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    await _auth.saveCredentials(
      token: _tokenController.text.trim(),
      driveId: _driveIdController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instellingen opgeslagen')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instellingen')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(labelText: 'API Token'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _driveIdController,
                    decoration: const InputDecoration(labelText: 'Drive ID'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Instellingen Opslaan'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final db = context.read<GalleryBloc>().db;

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Database wissen?'),
                          content: const Text('Alle lokale foto-gegevens worden verwijderd. Je moet opnieuw synchroniseren.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuleer')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Wis alles', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await db.clearDatabase();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Database gewist. Start een nieuwe sync.')),
                        );
                        navigator.pop();
                      }
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text('Wis lokale database', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
