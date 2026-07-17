import 'package:flutter/material.dart';
import 'package:kphoto/core/network/auth_repository.dart';
import 'package:kphoto/core/services/biometric_service.dart';
import 'package:kphoto/presentation/screens/gallery_screen.dart';
import 'package:kphoto/presentation/screens/connect_kdrive_screen.dart';
import 'package:kphoto/core/network/kdrive_api_service.dart';
import 'package:kphoto/core/services/permission_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kphoto/core/database/app_database.dart';
import 'package:kphoto/presentation/blocs/gallery_bloc.dart';
import 'package:kphoto/presentation/screens/initial_sync_screen.dart';

class FirebaseLoginScreen extends StatefulWidget {
  const FirebaseLoginScreen({super.key});

  @override
  State<FirebaseLoginScreen> createState() => _FirebaseLoginScreenState();
}

class _FirebaseLoginScreenState extends State<FirebaseLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthRepository();
  final _biometricService = BiometricService();
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    // Check direct of we door kunnen naar de gallerij
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PermissionService.checkAndRequestPermissions(context);
      _checkAutoLogin();
    });
  }

  Future<void> _checkAutoLogin() async {
    if (_auth.isFirebaseLoggedIn) {
      final useBiometrics = await _auth.isBiometricsEnabled();
      if (useBiometrics) {
        final authenticated = await _biometricService.authenticate();
        if (authenticated && mounted) {
          _navigateToNext();
        }
      } else {
        // Geen biometrie nodig, direct door
        _navigateToNext();
      }
    }
  }

  Future<void> _checkBiometrics() async {
    final authenticated = await _biometricService.authenticate();
    if (authenticated && mounted) {
      _navigateToNext();
    }
  }

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vul alle velden in')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await _auth.signUp(_emailController.text, _passwordController.text);
        // Voor nieuwe gebruikers direct door naar de nieuwe kDrive onboarding
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const ConnectKDriveScreen(),
          ));
        }
      } else {
        await _auth.signIn(_emailController.text, _passwordController.text);
        if (mounted) _navigateToNext();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fout: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Onverwachte fout: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToNext() async {
    final kdriveLoggedIn = await _auth.isLoggedIn();
    if (!mounted) return;

    if (kdriveLoggedIn) {
      // Direct naar de gallerij, geen blocking scherm meer
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const GalleryScreen()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const ConnectKDriveScreen(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AutofillGroup(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_library, size: 80, color: Colors.blue),
                const SizedBox(height: 16),
                const Text('K-Photo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Text('Privacy-first Cloud Gallery', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail', 
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Wachtwoord', 
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _handleAuth(),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _handleAuth,
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        child: Text(_isSignUp ? 'Account aanmaken' : 'Inloggen'),
                      ),
                      const SizedBox(height: 16),
                      // Optie voor biometrie aanbieden als er al een sessie is
                      if (_auth.isFirebaseLoggedIn)
                        OutlinedButton.icon(
                          onPressed: _checkBiometrics,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Inloggen met Biometrie'),
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        ),
                      TextButton(
                        onPressed: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(_isSignUp ? 'Heb je al een account? Log in' : 'Nog geen account? Registreer'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
