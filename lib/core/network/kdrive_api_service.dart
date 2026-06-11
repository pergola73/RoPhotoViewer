import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class KDriveApiService {
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
      final response = await _dio.get('/2/drive/$_driveId');
      debugPrint('kDrive API: Connected to drive $_driveId');
      debugPrint('kDrive API: Drive info: ${response.data}');
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        debugPrint('kDrive API: No Internet or DNS failed (api.infomaniak.com)');
      }
      debugPrint('kDrive API: Initialization failed');
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

  Future<void> downloadThumbnail(String fileId, String localPath) async {
    int retryCount = 0;
    while (retryCount < 3) {
      try {
        final response = await _dio.get(
          '/2/drive/$_driveId/files/$fileId/thumbnail',
          queryParameters: {'size': 400},
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
}
