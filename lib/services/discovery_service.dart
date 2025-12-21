import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/device_info.dart';
import 'device_service.dart';

class DiscoveryService {
  static const String multicastAddress = '224.0.0.167';
  static const int port = 53317;

  RawDatagramSocket? _socket;
  final DeviceService _deviceService;
  final Map<String, DeviceInfo> _discoveredDevices = {};
  final _devicesController = StreamController<List<DeviceInfo>>.broadcast();

  Stream<List<DeviceInfo>> get devicesStream => _devicesController.stream;
  List<DeviceInfo> get devices => _discoveredDevices.values.toList();

  DiscoveryService(this._deviceService);

  Future<void> start() async {
    await stop();

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reuseAddress: true,
        reusePort: true,
      );

      _socket!.joinMulticast(InternetAddress(multicastAddress));
      _socket!.broadcastEnabled = true;
      _socket!.multicastLoopback = false;

      _socket!.listen(_handleDatagram);

      // Send initial announcement
      await announce();

      print('[Discovery] Started listening on port $port');
    } catch (e) {
      print('[Discovery] Failed to start: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    _socket?.close();
    _socket = null;
    _discoveredDevices.clear();
    _devicesController.add([]);
  }

  Future<void> announce() async {
    if (_socket == null) return;

    final deviceInfo = _deviceService.deviceInfo;
    final message = utf8.encode(deviceInfo.toJsonString());

    _socket!.send(
      message,
      InternetAddress(multicastAddress),
      port,
    );

    print('[Discovery] Announced: ${deviceInfo.alias}');
  }

  void _handleDatagram(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;

    final datagram = _socket?.receive();
    if (datagram == null) return;

    try {
      final data = utf8.decode(datagram.data);
      final json = jsonDecode(data) as Map<String, dynamic>;
      final deviceInfo = DeviceInfo.fromJson(json, ip: datagram.address.address);

      // Ignore our own announcements
      if (deviceInfo.fingerprint == _deviceService.deviceInfo.fingerprint) {
        return;
      }

      addDevice(deviceInfo);

      // Respond to discovery with HTTP registration
      _respondToDiscovery(deviceInfo);
    } catch (e) {
      print('[Discovery] Failed to parse datagram: $e');
    }
  }

  void addDevice(DeviceInfo device) {
    final existing = _discoveredDevices[device.fingerprint];
    if (existing == null || existing.ip != device.ip) {
      _discoveredDevices[device.fingerprint] = device;
      _devicesController.add(devices);
      print('[Discovery] Found device: ${device.alias} at ${device.ip}:${device.port}');
    }
  }

  Future<void> _respondToDiscovery(DeviceInfo remoteDevice) async {
    HttpClient? client;
    try {
      final url = Uri.parse(
        '${remoteDevice.protocol}://${remoteDevice.ip}:${remoteDevice.port}/api/localsend/v2/register',
      );

      // Create client that accepts self-signed certificates
      client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;

      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.write(_deviceService.deviceInfo.toJsonString());
      final response = await request.close();
      await response.drain();
    } catch (e) {
      // Ignore registration failures - device might be offline
    } finally {
      client?.close();
    }
  }

  void removeDevice(String fingerprint) {
    _discoveredDevices.remove(fingerprint);
    _devicesController.add(devices);
  }

  void dispose() {
    stop();
    _devicesController.close();
  }
}
