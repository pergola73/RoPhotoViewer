import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class AuthRepository {
  final _storage = const FlutterSecureStorage();
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  static const _keyToken = 'kdrive_api_token';
  static const _keyDriveId = 'kdrive_id';
  static const _keyFolderIds = 'kdrive_folder_ids';
  static const _keyBiometrics = 'use_biometrics';
  static const _keyVerifier = 'pkce_verifier';

  static const String _clientId = 'd7ed6134-4670-4f92-aab3-94c08d624cc5';
  static const String _redirectUri = 'com.rvodevelopment.kphoto://oauth';
  static const String _authUrl = 'https://login.infomaniak.com/authorize';
  static const String _tokenUrl = 'https://api.infomaniak.com/2/oauth/token';

  // Helper voor PKCE
  String _generateRandomString(int length) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (i) => charset[random.nextInt(charset.length)]).join();
  }

  String _deriveChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  // Firebase Auth Methods
  Future<UserCredential?> signIn(String email, String password) async {
    final creds = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    await _syncFromFirestore();
    return creds;
  }

  Future<UserCredential?> signUp(String email, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  bool get isFirebaseLoggedIn => _firebaseAuth.currentUser != null;

  // Biometrics Preference
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometrics, value: enabled.toString());
  }

  Future<bool> isBiometricsEnabled() async {
    final value = await _storage.read(key: _keyBiometrics);
    return value == 'true';
  }

  Future<void> saveCredentials({
    required String token,
    required String driveId,
    required String folderId,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyDriveId, value: driveId);
    // Zorg dat folderId ook in de lijst staat als het er nog niet is
    final existingIds = await getFolderIds();
    if (!existingIds.contains(folderId)) {
      existingIds.add(folderId);
      await saveFolderIds(existingIds);
    } else {
      await _syncToFirestore();
    }
  }

  Future<void> saveFolderIds(List<String> ids) async {
    final value = ids.join(',');
    await _storage.write(key: _keyFolderIds, value: value);
    await _syncToFirestore();
  }

  // Sync to Firestore for multi-device support
  Future<void> _syncToFirestore() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final token = await _storage.read(key: _keyToken);
        final driveId = await _storage.read(key: _keyDriveId);
        final folderIds = await _storage.read(key: _keyFolderIds);

        debugPrint('AuthRepository: Instellingen backuppen naar Firestore voor ${user.email}...');
        
        await _firestore.collection('users').doc(user.uid).set({
          'kdrive_token': token,
          'kdrive_id': driveId,
          'kdrive_folder_ids': folderIds,
          'email': user.email,
          'last_sync': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
        
        debugPrint('AuthRepository: Backup geslaagd');
      }
    } catch (e) {
      debugPrint('AuthRepository: Firestore backup mislukt: $e');
    }
  }

  Future<void> _syncFromFirestore() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get().timeout(const Duration(seconds: 10));
        if (doc.exists) {
          final data = doc.data()!;
          if (data['kdrive_token'] != null) {
            await _storage.write(key: _keyToken, value: data['kdrive_token']);
          }
          if (data['kdrive_id'] != null) {
            await _storage.write(key: _keyDriveId, value: data['kdrive_id']);
          }
          if (data['kdrive_folder_ids'] != null) {
            await _storage.write(key: _keyFolderIds, value: data['kdrive_folder_ids']);
          }
        }
      }
    } catch (e) {
      debugPrint('AuthRepository: Firestore fetch failed: $e');
    }
  }

  Future<Map<String, String?>> getCredentials() async {
    final folderIds = await _storage.read(key: _keyFolderIds);
    return {
      'token': await _storage.read(key: _keyToken),
      'driveId': await _storage.read(key: _keyDriveId),
      'folderId': folderIds?.split(',').first,
      'folderIds': folderIds,
    };
  }

  Future<List<String>> getFolderIds() async {
    final ids = await _storage.read(key: _keyFolderIds);
    if (ids == null || ids.trim().isEmpty) {
      debugPrint('AuthRepository: Geen map ID\'s gevonden in opslag.');
      return [];
    }
    // Splits op komma, verwijder witruimte en filter lege resultaten
    final list = ids.split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet() // Verwijder dubbele IDs
        .toList();
    debugPrint('AuthRepository: Gevonden unieke map ID\'s: $list');
    return list;
  }

  Future<bool> isLoggedIn() async {
    final kdriveCreds = await getCredentials();
    return kdriveCreds['token'] != null && kdriveCreds['driveId'] != null;
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _storage.deleteAll();
  }

  Future<void> disconnectKDrive() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyDriveId);
    await _storage.delete(key: _keyFolderIds);
    await _syncToFirestore(); // Slaat de lege staat op in Firestore
  }

  // OAuth2 Methods
  Future<bool> connectWithKDrive() async {
    try {
      final verifier = _generateRandomString(64);
      await _storage.write(key: _keyVerifier, value: verifier);
      final challenge = _deriveChallenge(verifier);

      // Scope tijdelijk minimaal om invalid_scope te debuggen
      final url = '$_authUrl?client_id=$_clientId'
          '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
          '&response_type=code'
          '&scope=${Uri.encodeComponent('openid email profile kdrive')}'
          '&code_challenge=$challenge'
          '&code_challenge_method=S256';
      
      debugPrint('Auth Repository: Start OAuth flow met PKCE...');
      debugPrint('Auth Repository: Redirect URI is $_redirectUri');
      
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'com.rvodevelopment.kphoto',
        options: const FlutterWebAuth2Options(
          preferEphemeral: true,
        ),
      );

      debugPrint('Auth Repository: OAuth result ontvangen: $result');
      final code = Uri.parse(result).queryParameters['code'];
      
      if (code != null) {
        debugPrint('Auth Repository: Code gevonden, inwisselen voor token...');
        return await _exchangeCodeForToken(code);
      } else {
        final error = Uri.parse(result).queryParameters['error'];
        debugPrint('Auth Repository: Geen code gevonden in resultaat. Error: $error');
      }
    } catch (e) {
      debugPrint('Auth Repository: Fout tijdens OAuth flow: $e');
    }
    return false;
  }

  Future<bool> _exchangeCodeForToken(String code) async {
    try {
      final verifier = await _storage.read(key: _keyVerifier);
      
      final response = await Dio().post(_tokenUrl, data: {
        'grant_type': 'authorization_code',
        'client_id': _clientId,
        'redirect_uri': _redirectUri,
        'code': code,
        'code_verifier': verifier,
      });

      debugPrint('Auth Repository: Token exchange response status: ${response.statusCode}');

      if (response.data != null && response.data['access_token'] != null) {
        final token = response.data['access_token'].toString();
        await _storage.write(key: _keyToken, value: token);
        await _storage.delete(key: _keyVerifier);
        debugPrint('Auth Repository: Token succesvol opgeslagen via PKCE');
        return true;
      }
    } on DioException catch (e) {
      debugPrint('Auth Repository: Token exchange DioError: ${e.message}');
      debugPrint('Auth Repository: Response data: ${e.response?.data}');
    } catch (e) {
      debugPrint('Auth Repository: Onbekende fout bij token exchange: $e');
    }
    return false;
  }
}
