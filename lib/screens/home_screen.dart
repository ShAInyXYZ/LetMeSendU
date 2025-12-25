import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../main.dart' show settingsService;
import '../models/device_info.dart';
import '../providers/app_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/quick_send_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  LinkedDevice? _linkedDevice;
  bool _showQuickSendOverlay = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _linkedDevice = settingsService.getLinkedDevice();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().start();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _refreshLinkedDevice() {
    setState(() {
      _linkedDevice = settingsService.getLinkedDevice();
    });
  }

  // Public method to toggle QuickSend overlay (called from main.dart)
  void toggleQuickSendOverlay() {
    setState(() {
      _showQuickSendOverlay = !_showQuickSendOverlay;
    });
  }

  void _closeQuickSendOverlay() {
    setState(() {
      _showQuickSendOverlay = false;
    });
  }

  Future<void> _sendFilesToLinkedDevice(List<File> files) async {
    final provider = context.read<AppProvider>();
    final linked = _linkedDevice;

    if (linked == null || files.isEmpty) return;

    // Find the linked device in the current device list
    final targetDevice = provider.devices.firstWhere(
      (d) => d.fingerprint == linked.fingerprint,
      orElse: () => DeviceInfo(
        alias: linked.alias,
        version: '2.1',
        deviceModel: null,
        deviceType: DeviceType.desktop,
        fingerprint: linked.fingerprint,
        port: linked.port,
        protocol: linked.protocol,
        download: false,
        ip: linked.ip,
      ),
    );

    final result = await provider.sendFiles(targetDevice, files);

    if (mounted) {
      _closeQuickSendOverlay();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error_outline,
                color: result.success ? AppTheme.success : AppTheme.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.success
                      ? '${files.length} file(s) sent to ${linked.alias}'
                      : 'Failed: ${result.error}',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceLight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _showQuickSendOverlay) {
          _closeQuickSendOverlay();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedBackground(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Window controls and draggable header (desktop only)
              if (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
                SizedBox(
                  height: 40,
                  child: Stack(
                    children: [
                      // Draggable area covering the whole header
                      DragToMoveArea(
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                      // Window buttons on top
                      Positioned(
                        top: 4,
                        right: 12,
                        child: Row(
                          children: [
                            _WindowButton(
                              icon: Icons.remove_rounded,
                              onTap: () => windowManager.minimize(),
                              tooltip: 'Minimize',
                            ),
                            const SizedBox(width: 8),
                            _WindowButton(
                              icon: Icons.close_rounded,
                              onTap: () => windowManager.close(),
                              isClose: true,
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Centered Logo + Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 64,
                        height: 64,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SendU',
                      style: TextStyle(
                        fontFamily: 'Borel',
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Action buttons
                    Consumer<AppProvider>(
                      builder: (context, provider, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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

              // Device info section (name, IP, fingerprint)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    final currentName = settingsService.getDeviceName() ?? provider.deviceInfo.alias;
                    return GestureDetector(
                      onTap: () => _showDeviceNameDialog(),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          currentName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.edit_rounded,
                                        size: 14,
                                        color: AppTheme.accent,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (provider.isRunning && provider.localIp != null)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.lan_rounded,
                                          size: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${provider.localIp}:53317',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.fingerprint_rounded,
                                        size: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        provider.deviceInfo.fingerprint.substring(0, 8),
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Status indicator
                            Container(
                              width: 12,
                              height: 12,
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // WiFi & Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    if (!provider.isRunning && provider.sendProgress == null) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          if (provider.wifiName != null && provider.isRunning) ...[
                            const Icon(
                              Icons.wifi_rounded,
                              size: 14,
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.wifiName!,
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (provider.sendProgress != null)
                            _buildProgressIndicator(provider),
                        ],
                      ),
                    );
                  },
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
                          onLongPress: isLinked ? () => _showDeviceOptionsDialog(device) : null,
                        );
                      },
                    );
                  },
                ),
              ),
                  ],
                ),
              ),
            ),
            // QuickSend Overlay
            QuickSendOverlay(
              isVisible: _showQuickSendOverlay,
              onClose: _closeQuickSendOverlay,
              onFilesDropped: _sendFilesToLinkedDevice,
              hasLinkedDevice: _linkedDevice != null,
              onLinkDeviceRequest: () {
                // Focus goes back to main screen - no action needed
              },
            ),
          ],
        ),
        floatingActionButton: _showQuickSendOverlay
            ? null
            : Consumer<AppProvider>(
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

  void _showDeviceOptionsDialog(DeviceInfo device) {
    final linkedDevice = settingsService.getLinkedDevice();
    if (linkedDevice == null) return;

    final subfolderController = TextEditingController(text: linkedDevice.subfolder);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  _DeviceAvatar(deviceType: device.deviceType),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.alias,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${device.ip}:${device.port}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Subfolder path
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        size: 16,
                        color: AppTheme.accent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Save/Receive Folder',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: subfolderController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g., Phone, Work Phone',
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.backgroundDark,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  const SizedBox(height: 6),
                  Text(
                    'Files will be saved to and sent from this subfolder',
                    style: TextStyle(
                      color: AppTheme.textMuted.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final subfolder = subfolderController.text.trim();
                    if (subfolder.isNotEmpty) {
                      await settingsService.setLinkedDeviceSubfolder(subfolder);
                    }
                    Navigator.pop(context);
                    _refreshLinkedDevice();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Unlink button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await settingsService.clearLinkedDevice();
                    _refreshLinkedDevice();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_off_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Unlink Device',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
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
  final VoidCallback? onLongPress;

  const _DeviceCard({
    required this.device,
    required this.isLinked,
    required this.onSend,
    required this.onLink,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
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
                  if (isLinked) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Hold for options',
                      style: TextStyle(
                        color: AppTheme.textMuted.withOpacity(0.6),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
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

class _WindowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;
  final String? tooltip;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isClose
                ? AppTheme.error.withOpacity(0.1)
                : AppTheme.surfaceDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isClose ? AppTheme.error : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

