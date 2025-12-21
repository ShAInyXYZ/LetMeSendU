import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../models/device_info.dart';
import '../services/device_service.dart';
import '../services/file_sender.dart';
import '../services/settings_service.dart';

class QuickSendOverlay extends StatefulWidget {
  final SettingsService settingsService;
  final DeviceService deviceService;
  final VoidCallback onClose;

  const QuickSendOverlay({
    super.key,
    required this.settingsService,
    required this.deviceService,
    required this.onClose,
  });

  @override
  State<QuickSendOverlay> createState() => _QuickSendOverlayState();
}

class _QuickSendOverlayState extends State<QuickSendOverlay> {
  bool _isDragging = false;
  String? _statusMessage;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final linkedDevice = widget.settingsService.getLinkedDevice();

    return Positioned(
      right: 20,
      bottom: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragging
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: _isDragging ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
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
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),

              // Drop zone
              DropTarget(
                onDragEntered: (_) => setState(() => _isDragging = true),
                onDragExited: (_) => setState(() => _isDragging = false),
                onDragDone: (details) => _handleDrop(details, linkedDevice),
                child: Container(
                  height: 120,
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
                      style: BorderStyle.solid,
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

              // Linked device info
              Container(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Icon(
                      linkedDevice != null ? Icons.link : Icons.link_off,
                      size: 16,
                      color: linkedDevice != null
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        linkedDevice != null
                            ? linkedDevice.alias
                            : 'No linked device',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Status message
              if (_statusMessage != null && !_isSending)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    _statusMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _statusMessage!.contains('Error') || _statusMessage!.contains('No linked')
                          ? Theme.of(context).colorScheme.error
                          : Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
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
        _statusMessage = 'No valid files to send';
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

      // Clear success message after 3 seconds
      if (result.success) {
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
}
