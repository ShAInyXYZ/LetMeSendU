import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../models/device_info.dart';
import '../services/device_service.dart';
import '../services/file_sender.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class QuickSendWindow extends StatefulWidget {
  final SettingsService settingsService;
  final DeviceService deviceService;

  const QuickSendWindow({
    super.key,
    required this.settingsService,
    required this.deviceService,
  });

  @override
  State<QuickSendWindow> createState() => _QuickSendWindowState();
}

class _QuickSendWindowState extends State<QuickSendWindow> with WindowListener {
  bool _isDragging = false;
  String? _statusMessage;
  bool _isSending = false;
  Offset _dragOffset = Offset.zero;
  bool _isDraggingWindow = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _positionWindow();
  }

  Future<void> _positionWindow() async {
    try {
      await windowManager.setPosition(const Offset(1550, 750));
    } catch (e) {
      // Fallback position
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkedDevice = widget.settingsService.getLinkedDevice();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onPanStart: (details) {
          _isDraggingWindow = true;
          _dragOffset = details.globalPosition;
        },
        onPanUpdate: (details) async {
          if (_isDraggingWindow) {
            final delta = details.globalPosition - _dragOffset;
            final currentPos = await windowManager.getPosition();
            await windowManager.setPosition(currentPos + delta);
            _dragOffset = details.globalPosition;
          }
        },
        onPanEnd: (_) {
          _isDraggingWindow = false;
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragging ? AppTheme.primary : AppTheme.border,
              width: _isDragging ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.2),
                        AppTheme.surfaceDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.drag_indicator,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Quick Send',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // F11 badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Text(
                          'F11',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => exit(0),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Drop zone
                Expanded(
                  child: DropTarget(
                    onDragEntered: (_) => setState(() => _isDragging = true),
                    onDragExited: (_) => setState(() => _isDragging = false),
                    onDragDone: (details) => _handleDrop(details, linkedDevice),
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? AppTheme.primary.withOpacity(0.1)
                            : AppTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isDragging
                              ? AppTheme.primary
                              : AppTheme.border,
                          width: _isDragging ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: _isSending
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _statusMessage ?? 'Sending...',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _isDragging
                                          ? AppTheme.primary.withOpacity(0.2)
                                          : AppTheme.surfaceLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isDragging
                                          ? Icons.file_download_rounded
                                          : Icons.cloud_upload_rounded,
                                      size: 28,
                                      color: _isDragging
                                          ? AppTheme.primary
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _isDragging ? 'Drop to send!' : 'Drop files here',
                                    style: TextStyle(
                                      color: _isDragging
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: _isDragging
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                // Linked device info & status
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: linkedDevice != null
                                    ? AppTheme.success
                                    : AppTheme.error,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (linkedDevice != null
                                            ? AppTheme.success
                                            : AppTheme.error)
                                        .withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                linkedDevice != null
                                    ? linkedDevice.alias
                                    : 'No device linked',
                                style: TextStyle(
                                  color: linkedDevice != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (linkedDevice != null)
                              const Icon(
                                Icons.phone_android_rounded,
                                size: 14,
                                color: AppTheme.textMuted,
                              ),
                          ],
                        ),
                      ),
                      if (_statusMessage != null && !_isSending) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _isError
                                ? AppTheme.error.withOpacity(0.1)
                                : AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _isError
                                  ? AppTheme.error.withOpacity(0.3)
                                  : AppTheme.success.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isError
                                    ? Icons.error_outline_rounded
                                    : Icons.check_circle_outline_rounded,
                                size: 14,
                                color: _isError
                                    ? AppTheme.error
                                    : AppTheme.success,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _statusMessage!,
                                  style: TextStyle(
                                    color: _isError
                                        ? AppTheme.error
                                        : AppTheme.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isError =>
      _statusMessage != null &&
      (_statusMessage!.contains('Error') || _statusMessage!.contains('No linked'));

  Future<void> _handleDrop(DropDoneDetails details, LinkedDevice? linkedDevice) async {
    setState(() {
      _isDragging = false;
    });

    if (linkedDevice == null) {
      setState(() {
        _statusMessage = 'No linked device!';
      });
      return;
    }

    final files = details.files
        .map((xFile) => File(xFile.path))
        .where((file) => file.existsSync())
        .toList();

    if (files.isEmpty) {
      setState(() {
        _statusMessage = 'No valid files';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _statusMessage = 'Sending ${files.length} file(s)...';
    });

    try {
      final sender = FileSender(widget.deviceService);
      final target = DeviceInfo(
        alias: linkedDevice.alias,
        version: '2.1',
        deviceType: DeviceType.mobile,
        fingerprint: linkedDevice.fingerprint,
        port: linkedDevice.port,
        protocol: linkedDevice.protocol,
        ip: linkedDevice.ip,
      );

      final result = await sender.sendFiles(target, files);
      sender.dispose();

      setState(() {
        _isSending = false;
        _statusMessage = result.success
            ? 'Sent ${files.length} file(s)!'
            : 'Error: ${result.error}';
      });

      // Clear success message after delay
      if (result.success) {
        Future.delayed(const Duration(seconds: 2), () {
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
}
