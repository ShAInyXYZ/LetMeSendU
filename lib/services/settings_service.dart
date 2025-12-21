import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _linkedDeviceFingerprintKey = 'linked_device_fingerprint';
  static const String _linkedDeviceAliasKey = 'linked_device_alias';
  static const String _linkedDeviceIpKey = 'linked_device_ip';
  static const String _linkedDevicePortKey = 'linked_device_port';
  static const String _linkedDeviceProtocolKey = 'linked_device_protocol';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setLinkedDevice({
    required String fingerprint,
    required String alias,
    required String ip,
    required int port,
    required String protocol,
  }) async {
    await _prefs.setString(_linkedDeviceFingerprintKey, fingerprint);
    await _prefs.setString(_linkedDeviceAliasKey, alias);
    await _prefs.setString(_linkedDeviceIpKey, ip);
    await _prefs.setInt(_linkedDevicePortKey, port);
    await _prefs.setString(_linkedDeviceProtocolKey, protocol);
  }

  LinkedDevice? getLinkedDevice() {
    final fingerprint = _prefs.getString(_linkedDeviceFingerprintKey);
    final alias = _prefs.getString(_linkedDeviceAliasKey);
    final ip = _prefs.getString(_linkedDeviceIpKey);
    final port = _prefs.getInt(_linkedDevicePortKey);
    final protocol = _prefs.getString(_linkedDeviceProtocolKey);

    if (fingerprint == null || alias == null || ip == null || port == null || protocol == null) {
      return null;
    }

    return LinkedDevice(
      fingerprint: fingerprint,
      alias: alias,
      ip: ip,
      port: port,
      protocol: protocol,
    );
  }

  Future<void> clearLinkedDevice() async {
    await _prefs.remove(_linkedDeviceFingerprintKey);
    await _prefs.remove(_linkedDeviceAliasKey);
    await _prefs.remove(_linkedDeviceIpKey);
    await _prefs.remove(_linkedDevicePortKey);
    await _prefs.remove(_linkedDeviceProtocolKey);
  }
}

class LinkedDevice {
  final String fingerprint;
  final String alias;
  final String ip;
  final int port;
  final String protocol;

  LinkedDevice({
    required this.fingerprint,
    required this.alias,
    required this.ip,
    required this.port,
    required this.protocol,
  });
}
