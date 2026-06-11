import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final _storage = const FlutterSecureStorage();

  static const _keyToken = 'kdrive_api_token';
  static const _keyDriveId = 'kdrive_id';
  static const _keyFolderIds = 'kdrive_folder_ids'; // Slaat lijst op als comma-separated string

  Future<void> saveCredentials({
    required String token,
    required String driveId,
    required String folderId,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyDriveId, value: driveId);
    // Voor compatibiliteit met oude code, slaan we ook één op, 
    // maar we gaan naar een lijst toe.
    await _storage.write(key: _keyFolderIds, value: folderId);
  }

  Future<void> saveFolderIds(List<String> ids) async {
    await _storage.write(key: _keyFolderIds, value: ids.join(','));
  }

  Future<Map<String, String?>> getCredentials() async {
    final folderIds = await _storage.read(key: _keyFolderIds);
    return {
      'token': await _storage.read(key: _keyToken),
      'driveId': await _storage.read(key: _keyDriveId),
      'folderId': folderIds?.split(',').first, // Voor compatibiliteit
      'folderIds': folderIds,
    };
  }

  Future<List<String>> getFolderIds() async {
    final ids = await _storage.read(key: _keyFolderIds);
    if (ids == null || ids.isEmpty) return [];
    return ids.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<bool> isLoggedIn() async {
    final creds = await getCredentials();
    return creds['token'] != null && creds['driveId'] != null && creds['folderIds'] != null;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
