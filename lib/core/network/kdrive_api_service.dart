import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class KDriveApiService {
  // Singleton pattern om overal dezelfde verbinding te garanderen
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
      debugPrint('kDrive API: Verbinding maken met drive $_driveId...');
      await _dio.get('/2/drive/$_driveId').timeout(const Duration(seconds: 10));
      debugPrint('kDrive API: Succesvol verbonden');
    } catch (e) {
      debugPrint('kDrive API: Initialisatie mislukt: $e');
      rethrow;
    }
  }

  bool get isInitialized => _token != null && _driveId != null;

  Stream<List<dynamic>> getChildrenStream(String directoryId) async* {
    if (!isInitialized) return;

    String? cursor;
    bool hasMore = true;
    int retryCount = 0;

    debugPrint('kDrive API v3: Ophalen inhoud voor map $directoryId (Cursor-based)...');

    while (hasMore) {
      try {
        final Map<String, dynamic> queryParams = {
          'limit': 100,
        };
        if (cursor != null) {
          queryParams['cursor'] = cursor;
        }

        final response = await _dio.get(
          '/3/drive/$_driveId/files/$directoryId/files',
          queryParameters: queryParams,
        );

        final data = response.data;
        if (data is Map) {
          final List<dynamic> currentBatch = (data['data'] ?? []) as List<dynamic>;

          if (currentBatch.isEmpty) {
            debugPrint('kDrive API v3: Map $directoryId is leeg of einde bereikt.');
            hasMore = false;
            break;
          }

          debugPrint('kDrive API v3: Batch ontvangen voor $directoryId (${currentBatch.length} items)');
          yield currentBatch;

          // Haal de cursor op voor de volgende pagina
          cursor = data['cursor']?.toString();
          hasMore = cursor != null && cursor.isNotEmpty;
          
          if (!hasMore) {
            debugPrint('kDrive API v3: Geen cursor meer, map $directoryId volledig uitgelezen.');
          }

          // Verplichte pauze om rate limits te respecteren
          await Future.delayed(const Duration(milliseconds: 600));
        } else {
          hasMore = false;
        }
      } catch (e) {
        if (retryCount < 5) {
          retryCount++;
          final waitSeconds = retryCount * 5; 
          debugPrint('kDrive API v3: Netwerkfout, retry $retryCount/5 in $waitSeconds sec... ($e)');
          await Future.delayed(Duration(seconds: waitSeconds));
          continue;
        }
        debugPrint('kDrive API v3: Fataal netwerkprobleem na 5 pogingen: $e');
        hasMore = false;
        rethrow;
      }
    }
  }

  // Oude methode behouden voor compatibiliteit tijdens overgang of verwijderen als zeker
  Stream<List<dynamic>> listFilesStream(String directoryId) => getChildrenStream(directoryId);

  Future<void> downloadFile(String fileId, String localPath) async {
    try {
      final response = await _dio.get(
        '/2/drive/$_driveId/files/$fileId/download',
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      final data = response.data;
      if (data is List<int> && data.length < 2000) {
        try {
          final content = utf8.decode(data);
          final decoded = json.decode(content);
          if (decoded is Map && decoded['data'] != null && decoded['data']['url'] != null) {
            final url = decoded['data']['url'].toString();
            await Dio().download(url, localPath);
            return;
          }
        } catch (_) {}
      }

      if (data is List<int>) {
        final file = File(localPath);
        await file.writeAsBytes(data);
      }
    } catch (e) {
      debugPrint('kDrive API: Download error: $e');
      rethrow;
    }
  }

  Future<void> downloadThumbnail(String fileId, String localPath, {int size = 400}) async {
    int retryCount = 0;
    while (retryCount < 3) {
      try {
        final response = await _dio.get(
          '/2/drive/$_driveId/files/$fileId/thumbnail',
          queryParameters: {'size': size},
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode == 429) {
          debugPrint('kDrive API: Rate limit hit voor thumbnail $fileId, wachten...');
          await Future.delayed(const Duration(seconds: 10));
          retryCount++;
          continue;
        }

        final data = response.data;
        if (data is List<int>) {
          final file = File(localPath);
          await file.writeAsBytes(data);
          return;
        } else {
          debugPrint('kDrive API: Thumbnail error - Unexpected response type voor $fileId');
          return;
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= 3) {
          debugPrint('kDrive API: Thumbnail download mislukt na 3 pogingen voor $fileId: $e');
          rethrow;
        }
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      await _dio.delete('/2/drive/$_driveId/files/$fileId');
      debugPrint('kDrive API: Bestand $fileId verwijderd.');
    } catch (e) {
      debugPrint('kDrive API: Fout bij verwijderen bestand $fileId: $e');
      rethrow;
    }
  }

  /// Downloadt een klein deel van het originele bestand (voor EXIF extractie)
  Future<List<int>?> downloadPartialFile(String fileId, {int bytes = 1048576}) async {
    try {
      // Gebruik de bestaande _dio client met autorisatie en volg omleidingen
      final response = await _dio.get(
        '/2/drive/$_driveId/files/$fileId/download',
        options: Options(
          headers: {'Range': 'bytes=0-${bytes - 1}'},
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      final data = response.data;
      if (data is List<int>) {
        // Dubbele check of kDrive ons geen JSON URL teruggaf ipv bytes
        if (data.length < 2000) {
          try {
            final content = utf8.decode(data);
            final decoded = json.decode(content);
            if (decoded is Map && decoded['data'] != null && decoded['data']['url'] != null) {
              final url = decoded['data']['url'].toString();
              final partialResponse = await Dio().get(
                url,
                options: Options(
                  headers: {'Range': 'bytes=0-${bytes - 1}'},
                  responseType: ResponseType.bytes,
                ),
              );
              return partialResponse.data as List<int>?;
            }
          } catch (_) {}
        }
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Opent een stream naar het bestand voor slimme EXIF extractie
  Future<ResponseBody?> getDownloadStream(String fileId) async {
    try {
      // 1. Haal download URL op
      final response = await _dio.get(
        '/2/drive/$_driveId/files/$fileId/download',
        options: Options(responseType: ResponseType.json),
      );

      String? downloadUrl;
      if (response.data is Map && response.data['data'] != null) {
        downloadUrl = response.data['data']['url']?.toString();
      }

      if (downloadUrl == null) return null;

      // 2. Open de stream op de download URL
      final streamResponse = await Dio().get<ResponseBody>(
        downloadUrl,
        options: Options(responseType: ResponseType.stream),
      );

      return streamResponse.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFileExif(String fileId) async {
    int retryCount = 0;
    while (retryCount < 3) {
      try {
        // Gebruik v2 voor metadata omdat deze vaak completer is qua EXIF
        final response = await _dio.get('/2/drive/$_driveId/files/$fileId');
        
        final data = response.data;
        if (data is Map && data['data'] != null) {
          final fileData = data['data'];
          if (fileData['exif'] != null) {
            return fileData['exif'] as Map<String, dynamic>;
          }
          return fileData as Map<String, dynamic>;
        }
      } catch (e) {
        retryCount++;
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    return null;
  }
}
