import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/device_info.dart';

class DeviceService {
  static const String protocolVersion = '2.1';
  static const int defaultPort = 53317;

  late DeviceInfo _deviceInfo;
  DeviceInfo get deviceInfo => _deviceInfo;

  String? _customAlias;
  late final String _fingerprint;

  DeviceService({String? customAlias}) : _customAlias = customAlias {
    // Generate fingerprint once at startup - it stays the same for the session
    _fingerprint = const Uuid().v4();
    _deviceInfo = _createDeviceInfo();
    print('[DeviceService] Initialized with alias: ${_deviceInfo.alias}');
  }

  void setAlias(String alias) {
    _customAlias = alias;
    _deviceInfo = _createDeviceInfo();
    print('[DeviceService] Alias updated to: ${_deviceInfo.alias}');
  }

  DeviceInfo _createDeviceInfo() {
    final hostname = Platform.localHostname;
    final deviceType = _getDeviceType();

    String alias;
    if (_customAlias != null && _customAlias!.isNotEmpty) {
      alias = _customAlias!;
    } else if (Platform.isAndroid) {
      alias = 'LetMeSendU Mobile';
    } else {
      alias = 'LetMeSendU ($hostname)';
    }

    return DeviceInfo(
      alias: alias,
      version: protocolVersion,
      deviceModel: _getDeviceModel(),
      deviceType: deviceType,
      fingerprint: _fingerprint,
      port: defaultPort,
      protocol: 'http',
      download: true,
    );
  }

  DeviceType _getDeviceType() {
    if (Platform.isAndroid || Platform.isIOS) {
      return DeviceType.mobile;
    }
    return DeviceType.desktop;
  }

  String _getDeviceModel() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isLinux) {
      return 'Linux Desktop';
    } else if (Platform.isWindows) {
      return 'Windows Desktop';
    } else if (Platform.isMacOS) {
      return 'macOS Desktop';
    }
    return 'Unknown';
  }

  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // Filter out loopback and virtual interfaces
      final validInterfaces = interfaces.where((interface) {
        final name = interface.name.toLowerCase();
        return !name.startsWith('lo') &&
            !name.startsWith('docker') &&
            !name.startsWith('veth') &&
            !name.startsWith('br-') &&
            !name.startsWith('virbr') &&
            !name.startsWith('vmnet');
      }).toList();

      // Prioritize WiFi interfaces (wlan, wl, wifi, en for macOS)
      // These are more likely to be on the same network as other devices
      String? wifiIp;
      String? fallbackIp;

      for (final interface in validInterfaces) {
        final name = interface.name.toLowerCase();
        final isWifi = name.startsWith('wlan') ||
            name.startsWith('wl') ||
            name.startsWith('wifi') ||
            name.startsWith('en') || // macOS WiFi
            name.contains('wireless');

        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            if (isWifi && wifiIp == null) {
              wifiIp = addr.address;
            } else if (fallbackIp == null) {
              fallbackIp = addr.address;
            }
          }
        }
      }

      // Prefer WiFi IP, fall back to any other valid IP
      return wifiIp ?? fallbackIp;
    } catch (e) {
      print('[DeviceService] Failed to get local IP: $e');
    }
    return null;
  }

  Future<String?> getWifiName() async {
    try {
      final info = NetworkInfo();
      final wifiName = await info.getWifiName();
      // Remove quotes if present
      if (wifiName != null) {
        return wifiName.replaceAll('"', '');
      }
    } catch (e) {
      print('[DeviceService] Failed to get WiFi name: $e');
    }
    return null;
  }
}
