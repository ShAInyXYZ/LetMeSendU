import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show settingsService;
import '../models/device_info.dart';
import '../providers/app_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Device name (editable)
                  Expanded(
                    child: Consumer<AppProvider>(
                      builder: (context, provider, _) {
                        final currentName = settingsService.getDeviceName() ?? provider.deviceInfo.alias;
                        return GestureDetector(
                          onTap: () => _showDeviceNameDialog(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  currentName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: AppTheme.accent,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Action buttons
                  Consumer<AppProvider>(
                    builder: (context, provider, _) {
                      return Row(
                        children: [
                          _IconBtn(
                            icon: Icons.settings_rounded,
                            onTap: () => _showSettings(context),
                            tooltip: 'Settings',
                          ),
                          const SizedBox(width: 8),
                          _IconBtn(
                            icon: Icons.refresh_rounded,
                            onTap: provider.isRunning ? () => provider.refresh() : null,
                            tooltip: 'Refresh',
                          ),
                          const SizedBox(width: 8),
                          _IconBtn(
                            icon: provider.isRunning
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            onTap: () {
                              if (provider.isRunning) {
                                provider.stop();
                              } else {
                                provider.start();
                              }
                            },
                            isActive: provider.isRunning,
                            tooltip: provider.isRunning ? 'Stop' : 'Start',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Status card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Consumer<AppProvider>(
                builder: (context, provider, _) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        // Status indicator
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: provider.isRunning
                                ? AppTheme.success
                                : AppTheme.textMuted,
                            boxShadow: provider.isRunning
                                ? [
                                    BoxShadow(
                                      color: AppTheme.success.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.isRunning ? 'Online' : 'Offline',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (provider.wifiName != null && provider.isRunning)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.wifi_rounded,
                                      size: 12,
                                      color: AppTheme.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      provider.wifiName!,
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              Text(
                                provider.statusMessage ??
                                    (provider.isRunning
                                        ? '${provider.localIp}:53317'
                                        : 'Tap play to start'),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (provider.sendProgress != null)
                          _buildProgressIndicator(provider),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Quick Send bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: _linkedDevice != null
                      ? LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.15),
                            AppTheme.accent.withOpacity(0.1),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: _linkedDevice == null ? AppTheme.surfaceDark : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _linkedDevice != null
                        ? AppTheme.primary.withOpacity(0.3)
                        : AppTheme.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _linkedDevice != null ? Icons.link_rounded : Icons.link_off_rounded,
                      size: 18,
                      color: _linkedDevice != null
                          ? AppTheme.accent
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _linkedDevice != null
                            ? _linkedDevice!.alias
                            : 'No device linked',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _linkedDevice != null
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                    if (_linkedDevice != null)
                      GestureDetector(
                        onTap: () async {
                          await settingsService.clearLinkedDevice();
                          _refreshLinkedDevice();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Unlink',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'F11',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Text(
                    'Nearby Devices',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<AppProvider>(
                    builder: (context, provider, _) {
                      if (provider.devices.isEmpty) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${provider.devices.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Device list
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, _) {
                  if (!provider.isRunning) {
                    return _EmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Service Offline',
                      subtitle: 'Tap the play button to start discovering devices',
                    );
                  }

                  if (provider.devices.isEmpty) {
                    return _EmptyState(
                      icon: Icons.devices_rounded,
                      title: 'No Devices Found',
                      subtitle: 'Make sure other devices are running\nLocalSend on the same network',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
      ),
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (!provider.isRunning || provider.devices.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _pickAndSendFiles(null),
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send Files'),
            ),
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
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        const SizedBox(width: 8),
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
          ),
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
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
              const SizedBox(width: 12),
              Text('${device.alias} linked for Quick Send'),
            ],
          ),
          backgroundColor: AppTheme.surfaceLight,
        ),
      );
    }
  }

  Future<void> _pickAndSendFiles(DeviceInfo? preselectedDevice) async {
    final provider = context.read<AppProvider>();

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

    DeviceInfo? target = preselectedDevice;
    if (target == null && provider.devices.isNotEmpty) {
      target = await _showDeviceSelector(provider.devices);
    }

    if (target == null) return;

    final sendResult = await provider.sendFiles(target, files);

    if (!sendResult.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed: ${sendResult.error}')),
            ],
          ),
          backgroundColor: AppTheme.surfaceLight,
        ),
      );
    }
  }

  Future<DeviceInfo?> _showDeviceSelector(List<DeviceInfo> devices) async {
    return showModalBottomSheet<DeviceInfo>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Device',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...devices.map((device) => ListTile(
                leading: _DeviceAvatar(deviceType: device.deviceType),
                title: Text(device.alias),
                subtitle: Text(
                  '${device.ip}:${device.port}',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                onTap: () => Navigator.of(context).pop(device),
              )),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  void _showDeviceNameDialog() {
    final controller = TextEditingController(
      text: settingsService.getDeviceName() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Device Name',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set a name for this device so it\'s easier to identify on other devices.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., My Desktop, Work PC',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await settingsService.setDeviceName(name);
                // Update name in AppProvider (which updates DeviceService and re-announces)
                if (mounted) {
                  this.context.read<AppProvider>().updateDeviceName(name);
                }
              }
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Settings',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.badge_rounded, color: AppTheme.textSecondary),
              title: const Text('Device Name', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text(
                settingsService.getDeviceName() ?? this.context.read<AppProvider>().deviceInfo.alias,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeviceNameDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
              title: const Text('About', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: const Text('LetMeSendU v1.0.0', style: TextStyle(color: AppTheme.textMuted)),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('LetMeSendU', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            SizedBox(height: 12),
            Text(
              'A LocalSend-compatible file sharing app for Linux Desktop.',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              'Author: ShAInyXYZ',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;
  final String? tooltip;

  const _IconBtn({
    required this.icon,
    this.onTap,
    this.isActive = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary.withOpacity(0.15)
                : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppTheme.primary.withOpacity(0.3)
                  : AppTheme.border,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onTap == null
                ? AppTheme.textMuted
                : (isActive ? AppTheme.primary : AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceAvatar extends StatelessWidget {
  final DeviceType deviceType;

  const _DeviceAvatar({required this.deviceType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.2),
            AppTheme.accent.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getDeviceIcon(deviceType),
        color: AppTheme.primary,
        size: 22,
      ),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    return switch (type) {
      DeviceType.mobile => Icons.phone_android_rounded,
      DeviceType.desktop => Icons.computer_rounded,
      DeviceType.web => Icons.language_rounded,
      DeviceType.headless => Icons.terminal_rounded,
      DeviceType.server => Icons.dns_rounded,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLinked
              ? AppTheme.accent.withOpacity(0.5)
              : AppTheme.border,
          width: isLinked ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Device icon
          Stack(
            children: [
              _DeviceAvatar(deviceType: device.deviceType),
              if (isLinked)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.cardDark,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      size: 10,
                      color: AppTheme.backgroundDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Device info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.alias,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLinked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LINKED',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${device.deviceModel ?? device.deviceType.name} • ${device.ip}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isLinked)
                _ActionButton(
                  icon: Icons.link_rounded,
                  onTap: onLink,
                  tooltip: 'Link device',
                ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.send_rounded,
                onTap: onSend,
                isPrimary: true,
                tooltip: 'Send files',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final String? tooltip;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary ? null : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isPrimary ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
