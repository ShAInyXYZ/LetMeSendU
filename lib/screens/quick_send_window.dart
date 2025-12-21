import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../models/device_info.dart';
import '../services/device_service.dart';
import '../services/file_sender.dart';
import '../services/settings_service.dart';

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
    // Try to position in bottom-right of screen
    try {
      final bounds = await windowManager.getBounds();
      // Position near bottom-right (adjust based on your screen)
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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with drag handle and close button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.drag_indicator,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.send,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Quick Send',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => exit(0),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                            : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isDragging
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: _isSending
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(strokeWidth: 3),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _statusMessage ?? 'Sending...',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isDragging ? Icons.file_download : Icons.upload_file,
                                    size: 36,
                                    color: _isDragging
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isDragging ? 'Drop to send!' : 'Drop files here',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _isDragging
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: _isDragging ? FontWeight.bold : FontWeight.normal,
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
                      Row(
                        children: [
                          Icon(
                            linkedDevice != null ? Icons.link : Icons.link_off,
                            size: 14,
                            color: linkedDevice != null ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              linkedDevice != null
                                  ? linkedDevice.alias
                                  : 'No device linked',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_statusMessage != null && !_isSending) ...[
                        const SizedBox(height: 4),
                        Text(
                          _statusMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _statusMessage!.contains('Error') || _statusMessage!.contains('No linked')
                                ? Colors.red
                                : Colors.green,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
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

  Future<void> _handleDrop(DropDoneDetails details, LinkedDevice? linkedDevice) async {
    setState(() {
      _isDragging = false;
    });

    if (linkedDevice == null) {
      setState(() {
        _statusMessage = 'No linked device! Link one in main app.';
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

      // Clear success message and close after delay
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
