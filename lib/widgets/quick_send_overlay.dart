import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';

import '../theme/app_theme.dart';

class QuickSendOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;
  final Future<void> Function(List<File> files) onFilesDropped;
  final bool hasLinkedDevice;
  final VoidCallback? onLinkDeviceRequest;

  const QuickSendOverlay({
    super.key,
    required this.isVisible,
    required this.onClose,
    required this.onFilesDropped,
    required this.hasLinkedDevice,
    this.onLinkDeviceRequest,
  });

  @override
  State<QuickSendOverlay> createState() => _QuickSendOverlayState();
}

class _QuickSendOverlayState extends State<QuickSendOverlay>
    with TickerProviderStateMixin {
  bool _isDragging = false;
  bool _isSending = false;
  late AnimationController _boltController;
  late AnimationController _pulseController;
  late Animation<double> _boltAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _boltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _boltAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _boltController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _boltController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blurred dark background
          GestureDetector(
            onTap: widget.onClose,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          // Drop zone content
          Center(
            child: widget.hasLinkedDevice
                ? _buildDropZone()
                : _buildLinkDevicePrompt(),
          ),
          // Close button
          Positioned(
            top: 40,
            right: 24,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
          // ESC hint
          Positioned(
            top: 48,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ESC',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'to close',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
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

  Widget _buildDropZone() {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() {
          _isDragging = false;
          _isSending = true;
        });

        final files = details.files
            .map((xFile) => File(xFile.path))
            .where((file) => file.existsSync())
            .toList();

        if (files.isNotEmpty) {
          await widget.onFilesDropped(files);
        }

        setState(() => _isSending = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 320,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _isDragging
              ? AppTheme.primary.withOpacity(0.15)
              : AppTheme.surfaceDark.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isDragging
                ? AppTheme.primary
                : AppTheme.border,
            width: _isDragging ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isDragging
                  ? AppTheme.primary.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thunderbolt icon with animation - fixed size container
            SizedBox(
              width: 140,
              height: 140,
              child: AnimatedBuilder(
                animation: Listenable.merge([_boltAnimation, _pulseAnimation]),
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse rings
                      ...List.generate(3, (index) {
                        final delay = index * 0.3;
                        final pulseValue = (_pulseAnimation.value + delay) % 1.0;
                        return Container(
                          width: 80 + (pulseValue * 60),
                          height: 80 + (pulseValue * 60),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accent.withOpacity(0.3 * (1 - pulseValue)),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                      // Main icon container
                      Transform.scale(
                        scale: _boltAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isDragging
                                  ? [AppTheme.primary, AppTheme.accent]
                                  : [AppTheme.primaryDark, AppTheme.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isDragging ? AppTheme.accent : AppTheme.primary)
                                    .withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isSending
                                ? Icons.send_rounded
                                : Icons.bolt_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Text
            Text(
              _isSending
                  ? 'Sending...'
                  : (_isDragging ? 'Release to send!' : 'Drop your files here'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _isDragging ? AppTheme.accent : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isSending
                  ? 'Files are being transferred'
                  : 'Files will be sent to your linked device',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkDevicePrompt() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.link_off_rounded,
              size: 40,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Device Linked',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Link a device first to use Quick Send',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onClose();
                widget.onLinkDeviceRequest?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go to Main Screen',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
