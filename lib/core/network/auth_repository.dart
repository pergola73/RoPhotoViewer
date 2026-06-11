import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final _storage = const FlutterSecureStorage();

  static const _keyToken = 'kdrive_api_token';
  static const _keyDriveId = 'kdrive_id';
  static const _keyFolderId = 'kdrive_folder_id';

  Future<void> saveCredentials({
    required String token,
    required String driveId,
    required String folderId,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyDriveId, value: driveId);
    await _storage.write(key: _keyFolderId, value: folderId);
  }

  Future<Map<String, String?>> getCredentials() async {
    return {
      'token': await _storage.read(key: _keyToken),
      'driveId': await _storage.read(key: _keyDriveId),
      'folderId': await _storage.read(key: _keyFolderId),
    };
  }

  Future<bool> isLoggedIn() async {
    final creds = await getCredentials();
    return creds['token'] != null && creds['driveId'] != null && creds['folderId'] != null;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
