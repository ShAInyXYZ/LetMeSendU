import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../models/device_info.dart';
import '../models/file_info.dart';
import '../models/transfer_session.dart';
import 'device_service.dart';
import 'discovery_service.dart';

class ApiServer {
  static const int port = 53317;

  final DeviceService _deviceService;
  final DiscoveryService _discoveryService;

  HttpServer? _server;
  final Map<String, TransferSession> _sessions = {};

  final _transferRequestController = StreamController<TransferSession>.broadcast();
  final _transferProgressController = StreamController<FileTransferProgress>.broadcast();

  Stream<TransferSession> get transferRequests => _transferRequestController.stream;
  Stream<FileTransferProgress> get transferProgress => _transferProgressController.stream;

  String? _downloadPath;

  ApiServer(this._deviceService, this._discoveryService);

  Future<void> start() async {
    await stop();

    // Set up download directory
    final appDir = await getApplicationDocumentsDirectory();
    _downloadPath = p.join(appDir.path, 'LetMeSendU', 'Downloads');
    await Directory(_downloadPath!).create(recursive: true);

    final router = Router();

    // LocalSend API v2 endpoints
    router.get('/api/localsend/v2/info', _handleInfo);
    router.post('/api/localsend/v2/register', _handleRegister);
    router.post('/api/localsend/v2/prepare-upload', _handlePrepareUpload);
    router.post('/api/localsend/v2/upload', _handleUpload);
    router.post('/api/localsend/v2/cancel', _handleCancel);

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    print('[API] Server listening on port $port');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _sessions.clear();
  }

  Middleware _corsMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await handler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  Map<String, String> get _corsHeaders => {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  // GET /api/localsend/v2/info
  Future<Response> _handleInfo(Request request) async {
    return Response.ok(
      _deviceService.deviceInfo.toJsonString(),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // POST /api/localsend/v2/register
  Future<Response> _handleRegister(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      // Extract IP from request
      final ip = request.headers['x-forwarded-for'] ??
                 (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)?.remoteAddress.address;

      final deviceInfo = DeviceInfo.fromJson(json, ip: ip);

      // Ignore our own device
      if (deviceInfo.fingerprint != _deviceService.deviceInfo.fingerprint) {
        _discoveryService.addDevice(deviceInfo);
      }

      return Response.ok(
        _deviceService.deviceInfo.toJsonString(),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(body: 'Invalid request: $e');
    }
  }

  // POST /api/localsend/v2/prepare-upload
  Future<Response> _handlePrepareUpload(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final filesJson = json['files'] as Map<String, dynamic>;

      // Parse files
      final files = <String, FileInfo>{};
      for (final entry in filesJson.entries) {
        files[entry.key] = FileInfo.fromJson(entry.value as Map<String, dynamic>);
      }

      // Generate session ID and tokens
      final sessionId = const Uuid().v4();
      final tokens = <String, String>{};
      for (final fileId in files.keys) {
        tokens[fileId] = const Uuid().v4();
      }

      // Get sender IP
      final senderIp = (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
          ?.remoteAddress.address ?? 'unknown';

      // Create session
      final session = TransferSession(
        sessionId: sessionId,
        files: files,
        tokens: tokens,
        senderIp: senderIp,
      );
      _sessions[sessionId] = session;

      // Notify listeners about incoming transfer request
      _transferRequestController.add(session);

      // Build response with file tokens
      final fileTokens = <String, String>{};
      for (final entry in tokens.entries) {
        fileTokens[entry.key] = entry.value;
      }

      final response = {
        'sessionId': sessionId,
        'files': fileTokens,
      };

      print('[API] Prepared upload session $sessionId with ${files.length} files');

      return Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[API] prepare-upload error: $e');
      return Response.badRequest(body: 'Invalid request: $e');
    }
  }

  // POST /api/localsend/v2/upload
  Future<Response> _handleUpload(Request request) async {
    try {
      final sessionId = request.url.queryParameters['sessionId'];
      final fileId = request.url.queryParameters['fileId'];
      final token = request.url.queryParameters['token'];

      if (sessionId == null || fileId == null || token == null) {
        return Response.badRequest(body: 'Missing required parameters');
      }

      final session = _sessions[sessionId];
      if (session == null) {
        return Response(404, body: 'Session not found');
      }

      // Validate token
      if (session.tokens[fileId] != token) {
        return Response.forbidden('Invalid token');
      }

      final fileInfo = session.files[fileId];
      if (fileInfo == null) {
        return Response(404, body: 'File not found in session');
      }

      // Create file and write data
      final filePath = p.join(_downloadPath!, fileInfo.fileName);
      final file = File(filePath);
      final sink = file.openWrite();

      final progress = FileTransferProgress(
        fileId: fileId,
        fileName: fileInfo.fileName,
        totalBytes: fileInfo.size,
        status: TransferStatus.inProgress,
      );

      session.status = TransferStatus.inProgress;

      await for (final chunk in request.read()) {
        sink.add(chunk);
        progress.receivedBytes += chunk.length;
        _transferProgressController.add(progress);
      }

      await sink.close();

      progress.status = TransferStatus.completed;
      _transferProgressController.add(progress);

      print('[API] Received file: ${fileInfo.fileName} (${fileInfo.size} bytes)');

      return Response.ok('');
    } catch (e) {
      print('[API] upload error: $e');
      return Response.internalServerError(body: 'Upload failed: $e');
    }
  }

  // POST /api/localsend/v2/cancel
  Future<Response> _handleCancel(Request request) async {
    try {
      final sessionId = request.url.queryParameters['sessionId'];

      if (sessionId == null) {
        return Response.badRequest(body: 'Missing sessionId');
      }

      final session = _sessions.remove(sessionId);
      if (session != null) {
        session.status = TransferStatus.cancelled;
        print('[API] Session $sessionId cancelled');
      }

      return Response.ok('');
    } catch (e) {
      return Response.internalServerError(body: 'Cancel failed: $e');
    }
  }

  void dispose() {
    stop();
    _transferRequestController.close();
    _transferProgressController.close();
  }
}
