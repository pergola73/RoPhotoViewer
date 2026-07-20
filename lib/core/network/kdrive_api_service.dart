import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kphoto/core/network/auth_repository.dart';

class KDriveApiService {
  static final KDriveApiService _instance = KDriveApiService._internal();
  factory KDriveApiService() => _instance;
  KDriveApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.infomaniak.com',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));
  String? _token;
  String? _driveId;

  Future<void> initialize(String token, String driveId) async {
    _token = token;
    _driveId = driveId;
    _dio.options.headers['Authorization'] = 'Bearer $_token';
    try {
      await _dio.get('/2/drive/$_driveId').timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  bool get isInitialized => _token != null && _driveId != null;

  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  Future<List<Map<String, dynamic>>> getAvailableDrives() async {
    if (_token == null) return [];
    try {
      final response = await _dio.get('/2/drive');
      if (response.data is Map && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (_) {
      final response = await _dio.get('/2/kdrive');
      if (response.data is Map && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    }
    return [];
  }

  Stream<List<dynamic>> getChildrenStream(String directoryId) async* {
    if (!isInitialized) {
      final auth = AuthRepository();
      final creds = await auth.getCredentials();
      if (creds['token'] != null && creds['driveId'] != null) {
        await initialize(creds['token']!, creds['driveId']!);
      } else {
        return;
      }
    }

    _dio.options.headers['Authorization'] = 'Bearer $_token';
    String? cursor;
    bool hasMore = true;

    while (hasMore) {
      try {
        final Map<String, dynamic> queryParams = {'limit': 500};
        if (cursor != null) queryParams['cursor'] = cursor;

        final response = await _dio.get('/3/drive/$_driveId/files/$directoryId/files', queryParameters: queryParams);
        final data = response.data;
        if (data is Map) {
          final List<dynamic> currentBatch = (data['data'] ?? []) as List<dynamic>;
          if (currentBatch.isEmpty) break;
          yield currentBatch;
          cursor = data['cursor']?.toString();
          hasMore = cursor != null && cursor.isNotEmpty;
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          break;
        }
      } catch (_) {
        break;
      }
    }
  }

  Future<void> downloadFile(String fileId, String localPath) async {
    try {
      final response = await _dio.get('/2/drive/$_driveId/files/$fileId/download', options: Options(responseType: ResponseType.bytes, followRedirects: true));
      if (response.data is List<int>) {
        await File(localPath).writeAsBytes(response.data);
      }
    } catch (_) {}
  }

  Future<void> downloadThumbnail(String fileId, String localPath, {int size = 400}) async {
    try {
      final response = await _dio.get('/2/drive/$_driveId/files/$fileId/thumbnail', queryParameters: {'size': size}, options: Options(responseType: ResponseType.bytes, followRedirects: true));
      if (response.data is List<int>) {
        await File(localPath).writeAsBytes(response.data);
      }
    } catch (_) {}
  }

  Future<void> moveToTrash(String fileId) async => await _dio.delete('/2/drive/$_driveId/files/$fileId');
  Future<void> restoreFile(String fileId) async => await _dio.post('/2/drive/$_driveId/files/$fileId/restore');

  Future<List<dynamic>> getTrash() async {
    try {
      final response = await _dio.get('/2/drive/$_driveId/trash');
      return (response.data['data'] as List<dynamic>);
    } catch (_) {
      return [];
    }
  }

  Future<void> emptyTrash() async => await _dio.delete('/2/drive/$_driveId/trash');
  Future<void> deleteFilePermanent(String fileId) async => await _dio.delete('/2/drive/$_driveId/files/$fileId', queryParameters: {'force': true});

  Future<void> uploadDatabaseBackup(File dbFile) async {
    if (_driveId == null || _driveId!.isEmpty) {
      throw Exception('Drive ID is niet geconfigureerd.');
    }

    try {
      // 1. Zoek en verwijder oude backup
      final searchRes = await _dio.get('/2/drive/$_driveId/files/search', queryParameters: {'q': 'kphoto_index_backup.sqlite'});
      if (searchRes.data != null && searchRes.data['data'] != null) {
        for (var item in (searchRes.data['data'] as List)) {
          if (item['name'] == 'kphoto_index_backup.sqlite') {
            await deleteFilePermanent(item['id'].toString());
          }
        }
      }

      // 2. Universele upload methode: POST naar /files met Multipart
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(dbFile.path, filename: 'kphoto_index_backup.sqlite'),
        'directory_id': '0', // Root map
      });

      await _dio.post('/2/drive/$_driveId/files', data: formData);
      debugPrint('kDrive API: Backup succesvol voltooid.');
    } catch (e) {
      debugPrint('kDrive API: Backup mislukt (Post-files) - $e');
      rethrow;
    }
  }

  Future<String?> findDatabaseBackup() async {
    try {
      final response = await _dio.get('/2/drive/$_driveId/files/search', queryParameters: {'q': 'kphoto_index_backup.sqlite'});
      if (response.data['data'] != null && (response.data['data'] as List).isNotEmpty) {
        return response.data['data'][0]['id'].toString();
      }
    } catch (_) {}
    return null;
  }

  Future<List<int>?> downloadHeader(String fileId, {int bytes = 8192}) async {
    try {
      final response = await _dio.get('/2/drive/$_driveId/files/$fileId/download', options: Options(headers: {'Range': 'bytes=0-${bytes - 1}'}, responseType: ResponseType.bytes, followRedirects: true));
      return (response.data is List<int>) ? (response.data as List<int>) : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFileInfo(String fileId) async {
    try {
      final response = await _dio.get('/2/drive/$_driveId/files/$fileId');
      return response.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFileExif(String fileId) async {
    try {
      final response = await _dio.get('/2/drive/$_driveId/files/$fileId');
      return response.data['data']['exif'] ?? response.data['data'];
    } catch (_) {
      return null;
    }
  }
}
