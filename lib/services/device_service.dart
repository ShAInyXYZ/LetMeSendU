import 'dart:io';

import 'package:uuid/uuid.dart';

import '../models/device_info.dart';

class DeviceService {
  static const String protocolVersion = '2.1';
  static const int defaultPort = 53317;

  late final DeviceInfo _deviceInfo;
  DeviceInfo get deviceInfo => _deviceInfo;

  DeviceService() {
    _deviceInfo = _createDeviceInfo();
  }

  DeviceInfo _createDeviceInfo() {
    final fingerprint = const Uuid().v4();
    final hostname = Platform.localHostname;

    return DeviceInfo(
      alias: 'LetMeSendU ($hostname)',
      version: protocolVersion,
      deviceModel: _getDeviceModel(),
      deviceType: DeviceType.desktop,
      fingerprint: fingerprint,
      port: defaultPort,
      protocol: 'http', // We'll use HTTP for simplicity initially
      download: true,
    );
  }

  String _getDeviceModel() {
    if (Platform.isLinux) {
      return 'Linux Desktop';
    } else if (Platform.isWindows) {
      return 'Windows Desktop';
    } else if (Platform.isMacOS) {
      return 'macOS Desktop';
    }
    return 'Desktop';
  }

  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        // Skip loopback and docker/virtual interfaces
        if (interface.name.startsWith('lo') ||
            interface.name.startsWith('docker') ||
            interface.name.startsWith('veth') ||
            interface.name.startsWith('br-')) {
          continue;
        }

        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('[DeviceService] Failed to get local IP: $e');
    }
    return null;
  }
}
