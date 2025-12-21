import 'dart:convert';

enum DeviceType {
  mobile,
  desktop,
  web,
  headless,
  server;

  static DeviceType fromString(String? value) {
    return DeviceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeviceType.desktop,
    );
  }
}

class DeviceInfo {
  final String alias;
  final String version;
  final String? deviceModel;
  final DeviceType deviceType;
  final String fingerprint;
  final int port;
  final String protocol;
  final bool download;
  final String? ip;

  const DeviceInfo({
    required this.alias,
    required this.version,
    this.deviceModel,
    required this.deviceType,
    required this.fingerprint,
    required this.port,
    required this.protocol,
    this.download = false,
    this.ip,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json, {String? ip}) {
    return DeviceInfo(
      alias: json['alias'] as String,
      version: json['version'] as String,
      deviceModel: json['deviceModel'] as String?,
      deviceType: DeviceType.fromString(json['deviceType'] as String?),
      fingerprint: json['fingerprint'] as String,
      port: json['port'] as int,
      protocol: json['protocol'] as String,
      download: json['download'] as bool? ?? false,
      ip: ip,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alias': alias,
      'version': version,
      'deviceModel': deviceModel,
      'deviceType': deviceType.name,
      'fingerprint': fingerprint,
      'port': port,
      'protocol': protocol,
      'download': download,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  DeviceInfo copyWith({String? ip}) {
    return DeviceInfo(
      alias: alias,
      version: version,
      deviceModel: deviceModel,
      deviceType: deviceType,
      fingerprint: fingerprint,
      port: port,
      protocol: protocol,
      download: download,
      ip: ip ?? this.ip,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceInfo &&
          runtimeType == other.runtimeType &&
          fingerprint == other.fingerprint;

  @override
  int get hashCode => fingerprint.hashCode;

  @override
  String toString() => 'DeviceInfo($alias, $ip:$port, $deviceType)';
}
