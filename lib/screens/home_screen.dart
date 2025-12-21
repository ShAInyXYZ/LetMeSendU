import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show settingsService;
import '../models/device_info.dart';
import '../providers/app_provider.dart';
import '../services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LinkedDevice? _linkedDevice;

  @override
  void initState() {
    super.initState();
    _linkedDevice = settingsService.getLinkedDevice();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().start();
    });
  }

  void _refreshLinkedDevice() {
    setState(() {
      _linkedDevice = settingsService.getLinkedDevice();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LetMeSendU'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.isRunning ? () => provider.refresh() : null,
                tooltip: 'Refresh devices',
              );
            },
          ),
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(provider.isRunning ? Icons.stop : Icons.play_arrow),
                onPressed: () {
                  if (provider.isRunning) {
                    provider.stop();
                  } else {
                    provider.start();
                  }
                },
                tooltip: provider.isRunning ? 'Stop' : 'Start',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: provider.isRunning
                    ? Colors.green.shade100
                    : Colors.grey.shade200,
                child: Row(
                  children: [
                    Icon(
                      provider.isRunning ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: provider.isRunning ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.statusMessage ?? (provider.isRunning
                            ? 'Ready - ${provider.localIp}:53317'
                            : 'Not running'),
                        style: TextStyle(
                          fontSize: 12,
                          color: provider.isRunning
                              ? Colors.green.shade800
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    if (provider.sendProgress != null)
                      _buildProgressIndicator(provider),
                  ],
                ),
              );
            },
          ),

          // Linked device info bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _linkedDevice != null ? Icons.link : Icons.link_off,
                  size: 16,
                  color: _linkedDevice != null ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _linkedDevice != null
                        ? 'Quick Send: ${_linkedDevice!.alias}'
                        : 'No device linked for Quick Send',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_linkedDevice != null)
                  TextButton.icon(
                    onPressed: () async {
                      await settingsService.clearLinkedDevice();
                      _refreshLinkedDevice();
                    },
                    icon: const Icon(Icons.link_off, size: 16),
                    label: const Text('Unlink'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  'F11 for Quick Send',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Device list
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, provider, _) {
                if (!provider.isRunning) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Click the play button to start',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.devices.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.devices, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No devices found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Make sure other devices are running LocalSend\non the same network',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.devices.length,
                  itemBuilder: (context, index) {
                    final device = provider.devices[index];
                    final isLinked = _linkedDevice?.fingerprint == device.fingerprint;
                    return _DeviceCard(
                      device: device,
                      isLinked: isLinked,
                      onSend: () => _pickAndSendFiles(device),
                      onLink: () => _linkDevice(device),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (!provider.isRunning || provider.devices.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _pickAndSendFiles(null),
            icon: const Icon(Icons.send),
            label: const Text('Send Files'),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(AppProvider provider) {
    final progress = provider.sendProgress;
    if (progress == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (progress.totalFiles > 0)
          Text(
            '${progress.currentFile}/${progress.totalFiles}',
            style: const TextStyle(fontSize: 12),
          ),
        const SizedBox(width: 8),
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }

  Future<void> _linkDevice(DeviceInfo device) async {
    await settingsService.setLinkedDevice(
      fingerprint: device.fingerprint,
      alias: device.alias,
      ip: device.ip!,
      port: device.port,
      protocol: device.protocol,
    );
    _refreshLinkedDevice();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${device.alias} linked for Quick Send!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _pickAndSendFiles(DeviceInfo? preselectedDevice) async {
    final provider = context.read<AppProvider>();

    // Pick files
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    final files = result.files
        .where((f) => f.path != null)
        .map((f) => File(f.path!))
        .toList();

    if (files.isEmpty) return;

    // Select device if not preselected
    DeviceInfo? target = preselectedDevice;
    if (target == null && provider.devices.isNotEmpty) {
      target = await _showDeviceSelector(provider.devices);
    }

    if (target == null) return;

    // Send files
    final sendResult = await provider.sendFiles(target, files);

    if (!sendResult.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: ${sendResult.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<DeviceInfo?> _showDeviceSelector(List<DeviceInfo> devices) async {
    return showDialog<DeviceInfo>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Device'),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  leading: Icon(_getDeviceIcon(device.deviceType)),
                  title: Text(device.alias),
                  subtitle: Text('${device.ip}:${device.port}'),
                  onTap: () => Navigator.of(context).pop(device),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    return switch (type) {
      DeviceType.mobile => Icons.phone_android,
      DeviceType.desktop => Icons.computer,
      DeviceType.web => Icons.language,
      DeviceType.headless => Icons.terminal,
      DeviceType.server => Icons.dns,
    };
  }
}

class _DeviceCard extends StatelessWidget {
  final DeviceInfo device;
  final bool isLinked;
  final VoidCallback onSend;
  final VoidCallback onLink;

  const _DeviceCard({
    required this.device,
    required this.isLinked,
    required this.onSend,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLinked
            ? BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              child: Icon(_getDeviceIcon(device.deviceType)),
            ),
            if (isLinked)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.link,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text(device.alias),
            if (isLinked) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Linked',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${device.deviceModel ?? device.deviceType.name} - ${device.ip}:${device.port}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isLinked)
              IconButton(
                icon: const Icon(Icons.link),
                onPressed: onLink,
                tooltip: 'Link for Quick Send (F11)',
              ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: onSend,
              tooltip: 'Send files',
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    return switch (type) {
      DeviceType.mobile => Icons.phone_android,
      DeviceType.desktop => Icons.computer,
      DeviceType.web => Icons.language,
      DeviceType.headless => Icons.terminal,
      DeviceType.server => Icons.dns,
    };
  }
}
