import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/device_info.dart';
import '../models/transfer_session.dart';
import '../services/api_server.dart';
import '../services/device_service.dart';
import '../services/discovery_service.dart';
import '../services/file_sender.dart';

class AppProvider extends ChangeNotifier {
  late final DeviceService _deviceService;
  late final DiscoveryService _discoveryService;
  late final ApiServer _apiServer;
  late final FileSender _fileSender;

  List<DeviceInfo> _devices = [];
  List<DeviceInfo> get devices => _devices;

  String? _localIp;
  String? get localIp => _localIp;

  String? _wifiName;
  String? get wifiName => _wifiName;

  DeviceInfo get deviceInfo => _deviceService.deviceInfo;
  DeviceService get deviceService => _deviceService;
  DiscoveryService get discoveryService => _discoveryService;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  TransferSession? _pendingTransfer;
  TransferSession? get pendingTransfer => _pendingTransfer;

  SendProgress? _sendProgress;
  SendProgress? get sendProgress => _sendProgress;

  FileTransferProgress? _receiveProgress;
  FileTransferProgress? get receiveProgress => _receiveProgress;

  final List<ReceivedFile> _receivedFiles = [];
  List<ReceivedFile> get receivedFiles => _receivedFiles;

  // Separate list for notification overlay (can be dismissed)
  final List<ReceivedFile> _recentNotifications = [];
  List<ReceivedFile> get recentNotifications => _recentNotifications;

  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  AppProvider({String? deviceName}) {
    _deviceService = DeviceService(customAlias: deviceName);
    _discoveryService = DiscoveryService(_deviceService);
    _apiServer = ApiServer(_deviceService, _discoveryService);
    _fileSender = FileSender(_deviceService);

    _setupListeners();
  }

  void updateDeviceName(String name) {
    _deviceService.setAlias(name);
    // Re-announce with the new name
    _discoveryService.announce();
    notifyListeners();
  }

  void _setupListeners() {
    _discoveryService.devicesStream.listen((devices) {
      _devices = devices;
      notifyListeners();
    });

    _apiServer.transferRequests.listen((session) {
      _pendingTransfer = session;
      _statusMessage = 'Incoming transfer from ${session.senderIp}: ${session.fileCount} file(s)';
      notifyListeners();
    });

    _apiServer.transferProgress.listen((progress) {
      _receiveProgress = progress;
      if (progress.status == TransferStatus.completed && progress.filePath != null) {
        _statusMessage = 'Received: ${progress.fileName}';
        final receivedFile = ReceivedFile(
          fileName: progress.fileName,
          filePath: progress.filePath!,
          size: progress.totalBytes,
          receivedAt: DateTime.now(),
        );
        // Add to permanent received files list (for gallery)
        _receivedFiles.insert(0, receivedFile);
        // Add to notifications list (can be dismissed)
        _recentNotifications.insert(0, receivedFile);
        // Keep notifications limited to 5
        if (_recentNotifications.length > 5) {
          _recentNotifications.removeLast();
        }
      }
      notifyListeners();
    });

    _fileSender.progressStream.listen((progress) {
      _sendProgress = progress;
      _statusMessage = progress.message;
      notifyListeners();
    });
  }

  Future<void> start() async {
    if (_isRunning) return;

    try {
      _localIp = await _deviceService.getLocalIpAddress();
      _wifiName = await _deviceService.getWifiName();
      await _apiServer.start();
      await _discoveryService.start();
      _isRunning = true;
      _statusMessage = 'Running on $_localIp:${DeviceService.defaultPort}';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Failed to start: $e';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _discoveryService.stop();
    await _apiServer.stop();
    _isRunning = false;
    _statusMessage = 'Stopped';
    notifyListeners();
  }

  Future<void> refresh() async {
    await _discoveryService.announce();
  }

  Future<SendResult> sendFiles(DeviceInfo target, List<File> files) async {
    return await _fileSender.sendFiles(target, files);
  }

  void clearStatus() {
    _statusMessage = null;
    _sendProgress = null;
    _receiveProgress = null;
    _pendingTransfer = null;
    notifyListeners();
  }

  void dismissNotification(ReceivedFile file) {
    _recentNotifications.remove(file);
    notifyListeners();
  }

  void clearNotifications() {
    _recentNotifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _discoveryService.dispose();
    _apiServer.dispose();
    _fileSender.dispose();
    super.dispose();
  }
}
