import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final _storage = const FlutterSecureStorage();
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  static const _keyToken = 'kdrive_api_token';
  static const _keyDriveId = 'kdrive_id';
  static const _keyFolderIds = 'kdrive_folder_ids';
  static const _keyBiometrics = 'use_biometrics';

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
        .toList();
    debugPrint('AuthRepository: Gevonden map ID\'s: $list');
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
}
