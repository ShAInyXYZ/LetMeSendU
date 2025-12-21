import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/device_info.dart';
import 'device_service.dart';

class FileSender {
  final DeviceService _deviceService;

  final _progressController = StreamController<SendProgress>.broadcast();
  Stream<SendProgress> get progressStream => _progressController.stream;

  FileSender(this._deviceService);

  /// Creates an HttpClient that accepts self-signed certificates
  HttpClient _createHttpClient() {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }

  Future<SendResult> sendFiles(DeviceInfo target, List<File> files) async {
    final httpClient = _createHttpClient();

    try {
      // Prepare file metadata
      final filesMap = <String, Map<String, dynamic>>{};
      final fileList = <String, File>{};

      for (final file in files) {
        final fileId = const Uuid().v4();
        final stat = await file.stat();
        final bytes = await file.readAsBytes();
        final hash = sha256.convert(bytes).toString();

        filesMap[fileId] = {
          'id': fileId,
          'fileName': p.basename(file.path),
          'size': stat.size,
          'fileType': _getMimeType(file.path),
          'sha256': hash,
        };
        fileList[fileId] = file;
      }

      // Step 1: Prepare upload
      final prepareUrl = Uri.parse(
        '${target.protocol}://${target.ip}:${target.port}/api/localsend/v2/prepare-upload',
      );

      final prepareBody = jsonEncode({
        'info': _deviceService.deviceInfo.toJson(),
        'files': filesMap,
      });

      _progressController.add(SendProgress(
        status: SendStatus.preparing,
        message: 'Preparing upload...',
      ));

      final prepareRequest = await httpClient.postUrl(prepareUrl);
      prepareRequest.headers.contentType = ContentType.json;
      prepareRequest.write(prepareBody);
      final prepareResponse = await prepareRequest.close();

      if (prepareResponse.statusCode != 200) {
        return SendResult.failure('Prepare failed: ${prepareResponse.statusCode}');
      }

      final prepareResponseBody = await prepareResponse.transform(utf8.decoder).join();
      final prepareData = jsonDecode(prepareResponseBody) as Map<String, dynamic>;
      final sessionId = prepareData['sessionId'] as String;
      final tokens = prepareData['files'] as Map<String, dynamic>;

      // Step 2: Upload each file
      var completedFiles = 0;
      final totalFiles = files.length;

      for (final entry in fileList.entries) {
        final fileId = entry.key;
        final file = entry.value;
        final token = tokens[fileId] as String;

        _progressController.add(SendProgress(
          status: SendStatus.uploading,
          message: 'Uploading ${p.basename(file.path)}...',
          currentFile: completedFiles + 1,
          totalFiles: totalFiles,
        ));

        final uploadUrl = Uri.parse(
          '${target.protocol}://${target.ip}:${target.port}/api/localsend/v2/upload'
          '?sessionId=$sessionId&fileId=$fileId&token=$token',
        );

        final bytes = await file.readAsBytes();
        final uploadRequest = await httpClient.postUrl(uploadUrl);
        uploadRequest.headers.contentType = ContentType.binary;
        uploadRequest.add(bytes);
        final uploadResponse = await uploadRequest.close();

        if (uploadResponse.statusCode != 200) {
          return SendResult.failure('Upload failed: ${uploadResponse.statusCode}');
        }

        // Drain the response
        await uploadResponse.drain();

        completedFiles++;
      }

      _progressController.add(SendProgress(
        status: SendStatus.completed,
        message: 'Transfer complete!',
        currentFile: totalFiles,
        totalFiles: totalFiles,
      ));

      return SendResult.success();
    } catch (e) {
      _progressController.add(SendProgress(
        status: SendStatus.failed,
        message: 'Error: $e',
      ));
      return SendResult.failure('$e');
    } finally {
      httpClient.close();
    }
  }

  String _getMimeType(String path) {
    final ext = p.extension(path).toLowerCase();
    return switch (ext) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.gif' => 'image/gif',
      '.webp' => 'image/webp',
      '.pdf' => 'application/pdf',
      '.txt' => 'text/plain',
      '.json' => 'application/json',
      '.mp4' => 'video/mp4',
      '.mp3' => 'audio/mpeg',
      '.zip' => 'application/zip',
      '.doc' => 'application/msword',
      '.docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => 'application/octet-stream',
    };
  }

  void dispose() {
    _progressController.close();
  }
}

enum SendStatus {
  preparing,
  uploading,
  completed,
  failed,
  cancelled,
}

class SendProgress {
  final SendStatus status;
  final String message;
  final int currentFile;
  final int totalFiles;
  final double? fileProgress;

  SendProgress({
    required this.status,
    required this.message,
    this.currentFile = 0,
    this.totalFiles = 0,
    this.fileProgress,
  });
}

class SendResult {
  final bool success;
  final String? error;

  SendResult.success() : success = true, error = null;
  SendResult.failure(this.error) : success = false;
}
