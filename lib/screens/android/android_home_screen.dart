import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../models/device_info.dart';
import '../../models/transfer_session.dart';
import '../../providers/app_provider.dart';
import '../../services/file_sender.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_background.dart';
import 'gallery_screen.dart';

class AndroidHomeScreen extends StatefulWidget {
  const AndroidHomeScreen({super.key});

  @override
  State<AndroidHomeScreen> createState() => _AndroidHomeScreenState();
}

class _AndroidHomeScreenState extends State<AndroidHomeScreen> {
  bool _isSending = false;
  String? _statusMessage;
  double _sendProgress = 0;
  Timer? _refreshTimer;
  String? _localIp;
  String? _wifiName;

  @override
  void initState() {
    super.initState();
    _fetchNetworkInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().start();
      _startAutoRefresh();
    });
  }

  Future<void> _fetchNetworkInfo() async {
    final ip = await deviceService.getLocalIpAddress();
    final wifi = await deviceService.getWifiName();
    if (mounted) {
      setState(() {
        _localIp = ip;
        _wifiName = wifi;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        context.read<AppProvider>().refresh();
      }
    });
  }

  void _manualRefresh() {
    context.read<AppProvider>().refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing devices...'),
        backgroundColor: AppTheme.surfaceLight,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GalleryScreen(),
      ),
    );
  }

  // Get unique devices by IP (no duplicates)
  List<DeviceInfo> _getUniqueDevices(List<DeviceInfo> devices) {
    final seen = <String>{};
    return devices.where((device) {
      final key = device.ip ?? device.fingerprint;
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: AnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Consumer<AppProvider>(
                      builder: (context, provider, _) {
                        return _buildContent(provider);
                      },
                    ),
                  ),
                ],
              ),
              // Received files overlay
              Consumer<AppProvider>(
                builder: (context, provider, _) {
                  return _buildReceivedFilesOverlay(provider);
                },
              ),
              // Receiving progress indicator
              Consumer<AppProvider>(
                builder: (context, provider, _) {
                  return _buildReceivingIndicator(provider);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildReceivingIndicator(AppProvider provider) {
    final progress = provider.receiveProgress;
    if (progress == null || progress.status != TransferStatus.inProgress) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accent.withOpacity(0.9),
              AppTheme.primary.withOpacity(0.9),
            ],
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Receiving: ${progress.fileName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress.progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress.progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedFilesOverlay(AppProvider provider) {
    final notifications = provider.recentNotifications;
    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: notifications.take(3).map((file) {
          return _buildReceivedFileCard(file, provider);
        }).toList(),
      ),
    );
  }

  Widget _buildReceivedFileCard(ReceivedFile file, AppProvider provider) {
    return Dismissible(
      key: Key(file.filePath),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => provider.dismissNotification(file),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.success.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openFile(file),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildFilePreview(file),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: AppTheme.success,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'File Received',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          file.fileName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatFileSize(file.size),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _openFile(file),
                        icon: const Icon(Icons.open_in_new_rounded, size: 20),
                        color: AppTheme.accent,
                        tooltip: 'Open file',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      IconButton(
                        onPressed: () => provider.dismissNotification(file),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: AppTheme.textMuted,
                        tooltip: 'Dismiss',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(ReceivedFile file) {
    final fileExists = File(file.filePath).existsSync();

    if (file.isImage && fileExists) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(file.filePath),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFileIcon(file),
        ),
      );
    }

    return _buildFileIcon(file);
  }

  Widget _buildFileIcon(ReceivedFile file) {
    IconData icon;
    Color color;

    if (file.isImage) {
      icon = Icons.image_rounded;
      color = Colors.pink;
    } else if (file.isVideo) {
      icon = Icons.video_file_rounded;
      color = Colors.purple;
    } else if (file.fileName.toLowerCase().endsWith('.pdf')) {
      icon = Icons.picture_as_pdf_rounded;
      color = Colors.red;
    } else if (file.fileName.toLowerCase().endsWith('.zip') ||
               file.fileName.toLowerCase().endsWith('.rar')) {
      icon = Icons.folder_zip_rounded;
      color = Colors.orange;
    } else if (file.fileName.toLowerCase().endsWith('.mp3') ||
               file.fileName.toLowerCase().endsWith('.wav')) {
      icon = Icons.audio_file_rounded;
      color = Colors.teal;
    } else {
      icon = Icons.insert_drive_file_rounded;
      color = AppTheme.accent;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 28,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _openFile(ReceivedFile file) async {
    try {
      await OpenFile.open(file.filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildHeader() {
    final provider = context.read<AppProvider>();
    final currentName = settingsService.getDeviceName() ?? provider.deviceInfo.alias;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Centered Logo + Title
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/logo.png',
                  width: 72,
                  height: 72,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SendU',
                style: TextStyle(
                  fontFamily: 'Borel',
                  fontSize: 36,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Device info card
          GestureDetector(
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
                        if (_wifiName != null || _localIp != null)
                          Row(
                            children: [
                              if (_wifiName != null) ...[
                                const Icon(
                                  Icons.wifi_rounded,
                                  size: 12,
                                  color: AppTheme.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _wifiName!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              if (_localIp != null) ...[
                                const Icon(
                                  Icons.lan_rounded,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$_localIp:53317',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
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
                            const SizedBox(width: 4),
                            Text(
                              provider.deviceInfo.fingerprint.substring(0, 8),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
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
                      color: context.watch<AppProvider>().isRunning
                          ? AppTheme.success
                          : AppTheme.textMuted,
                      boxShadow: context.watch<AppProvider>().isRunning
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
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppProvider provider) {
    final uniqueDevices = _getUniqueDevices(provider.devices);
    final linkedDevice = settingsService.getLinkedDevice();

    if (_isSending) {
      return _buildSendingState();
    }

    if (_statusMessage != null) {
      return _buildStatusMessage();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text(
                'Nearby Devices (${uniqueDevices.length})',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (provider.isRunning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_rounded, size: 12, color: AppTheme.success),
                      SizedBox(width: 4),
                      Text(
                        'Online',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: uniqueDevices.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async {
                    _manualRefresh();
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: AppTheme.accent,
                  backgroundColor: AppTheme.surfaceDark,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: uniqueDevices.length,
                    itemBuilder: (context, index) {
                      final device = uniqueDevices[index];
                      final isLinked = linkedDevice?.fingerprint == device.fingerprint ||
                          linkedDevice?.ip == device.ip;
                      return _buildDeviceCard(device, isLinked);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.devices_rounded,
              size: 48,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No devices found',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Make sure other devices are on\nthe same network with LocalSend open',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _manualRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(DeviceInfo device, bool isLinked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLinked ? AppTheme.success.withOpacity(0.5) : AppTheme.border,
          width: isLinked ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _linkDevice(device),
          onLongPress: isLinked ? () => _showDeviceOptionsDialog(device) : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.8),
                        AppTheme.accent.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDeviceIcon(device.deviceType),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
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
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLinked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LINKED',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${device.ip ?? "Unknown"}:${device.port}',
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
                Icon(
                  isLinked ? Icons.check_circle_rounded : Icons.add_link_rounded,
                  color: isLinked ? AppTheme.success : AppTheme.textMuted,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
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
          width: 320,
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.8),
                          AppTheme.accent.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getDeviceIcon(device.deviceType),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
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
                      hintText: 'e.g., Desktop, Work PC',
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
                    setState(() {});
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
                  onPressed: () {
                    Navigator.pop(context);
                    _unlinkDevice();
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

  Widget _buildSendingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: _sendProgress > 0 ? _sendProgress : null,
              strokeWidth: 4,
              valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
              backgroundColor: AppTheme.surfaceLight,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _statusMessage ?? 'Sending...',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    final isError = _statusMessage!.contains('Error') || _statusMessage!.contains('No');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (isError ? AppTheme.error : AppTheme.success).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              size: 48,
              color: isError ? AppTheme.error : AppTheme.success,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _statusMessage!,
            style: TextStyle(
              color: isError ? AppTheme.error : AppTheme.success,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              setState(() {
                _statusMessage = null;
              });
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    final linkedDevice = settingsService.getLinkedDevice();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Browse/Gallery button on the left
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _openGallery(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.folder_rounded),
                label: const Text(
                  'Browse',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          if (linkedDevice != null && !_isSending) ...[
            const SizedBox(width: 12),
            // Send Files button on the right
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _pickAndSendFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'Send Files',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.mobile:
        return Icons.phone_android_rounded;
      case DeviceType.desktop:
        return Icons.computer_rounded;
      case DeviceType.web:
        return Icons.language_rounded;
      case DeviceType.headless:
        return Icons.dns_rounded;
      case DeviceType.server:
        return Icons.storage_rounded;
    }
  }

  void _linkDevice(DeviceInfo device) {
    if (device.ip == null) return;
    settingsService.setLinkedDevice(
      alias: device.alias,
      fingerprint: device.fingerprint,
      ip: device.ip!,
      port: device.port,
      protocol: device.protocol,
    );
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Linked to ${device.alias}'),
        backgroundColor: AppTheme.surfaceLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _unlinkDevice() {
    settingsService.clearLinkedDevice();
    setState(() {});
  }

  Future<void> _pickAndSendFiles() async {
    final linkedDevice = settingsService.getLinkedDevice();
    if (linkedDevice == null) return;

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

    setState(() {
      _isSending = true;
      _statusMessage = 'Sending ${files.length} file(s)...';
    });

    try {
      final sender = FileSender(deviceService);
      final target = DeviceInfo(
        alias: linkedDevice.alias,
        version: '2.1',
        deviceType: DeviceType.mobile,
        fingerprint: linkedDevice.fingerprint,
        port: linkedDevice.port,
        protocol: linkedDevice.protocol,
        ip: linkedDevice.ip,
      );

      final sendResult = await sender.sendFiles(target, files);
      sender.dispose();

      setState(() {
        _isSending = false;
        _statusMessage = sendResult.success
            ? 'Sent ${files.length} file(s) successfully!'
            : 'Error: ${sendResult.error}';
      });

      if (sendResult.success) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _statusMessage = null;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        _statusMessage = 'Error: $e';
      });
    }
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
                hintText: 'e.g., My Phone, Work Phone',
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
                  context.read<AppProvider>().updateDeviceName(name);
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
