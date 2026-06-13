import 'package:flutter/material.dart';
import 'package:k_photo/core/network/auth_repository.dart';
import 'package:k_photo/core/network/kdrive_api_service.dart';
import 'package:k_photo/presentation/screens/gallery_screen.dart';

class LoginScreen extends StatefulWidget {
  final KDriveApiService apiService;
  final AuthRepository authRepository;

  const LoginScreen({
    super.key,
    required this.apiService,
    required this.authRepository,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _tokenController = TextEditingController();
  final _driveIdController = TextEditingController();
  final _folderIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final creds = await widget.authRepository.getCredentials();
    if (creds['token'] != null) _tokenController.text = creds['token']!;
    if (creds['driveId'] != null) _driveIdController.text = creds['driveId']!;
    if (creds['folderId'] != null) _folderIdController.text = creds['folderId']!;
  }

  Future<void> _login() async {
    final token = _tokenController.text.trim();
    final driveId = _driveIdController.text.trim();
    final folderId = _folderIdController.text.trim();

    if (token.isEmpty || driveId.isEmpty || folderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.apiService.initialize(token, driveId);
      await widget.authRepository.saveCredentials(
        token: token, 
        driveId: driveId,
        folderId: folderId,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GalleryScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login to K-Photo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Enter your Infomaniak API Token and Drive ID to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'API Token',
                  helperText: 'Create a token with kDrive scope in Manager',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _driveIdController,
                decoration: const InputDecoration(
                  labelText: 'Drive ID',
                  helperText: 'Found in the kDrive URL (e.g. 123456)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _folderIdController,
                decoration: const InputDecoration(
                  labelText: 'Root Folder ID',
                  helperText: 'ID of the folder you want to sync (e.g. 3377)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Connect to kDrive'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
