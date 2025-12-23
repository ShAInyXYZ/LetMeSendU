import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../../models/transfer_session.dart';
import '../../theme/app_theme.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const String _downloadPath = '/storage/emulated/0/Download/LetMeSendU';

  FileCategory? _selectedCategory;
  List<ReceivedFile> _allFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFilesFromDisk();
  }

  Future<void> _loadFilesFromDisk() async {
    setState(() => _isLoading = true);

    try {
      final dir = Directory(_downloadPath);
      if (!await dir.exists()) {
        setState(() {
          _allFiles = [];
          _isLoading = false;
        });
        return;
      }

      final files = <ReceivedFile>[];
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final fileName = entity.path.split('/').last;
          files.add(ReceivedFile(
            fileName: fileName,
            filePath: entity.path,
            size: stat.size,
            receivedAt: stat.modified,
          ));
        }
      }

      // Sort by date, newest first
      files.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

      setState(() {
        _allFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      print('[Gallery] Error loading files: $e');
      setState(() {
        _allFiles = [];
        _isLoading = false;
      });
    }
  }

  List<ReceivedFile> get _filteredFiles {
    if (_selectedCategory == null) return _allFiles;
    return _allFiles.where((f) => f.category == _selectedCategory).toList();
  }

  Map<String, List<ReceivedFile>> _getGroupedByDate(List<ReceivedFile> files) {
    final grouped = <String, List<ReceivedFile>>{};
    for (final file in files) {
      final dateKey = _getDateLabel(file.receivedAt);
      grouped.putIfAbsent(dateKey, () => []).add(file);
    }
    return grouped;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final fileDate = DateTime(date.year, date.month, date.day);

    if (fileDate == today) return 'Today';
    if (fileDate == yesterday) return 'Yesterday';
    if (now.difference(date).inDays < 7) return 'This Week';
    if (now.difference(date).inDays < 30) return 'This Month';
    return '${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Received Files',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_filteredFiles.length} files',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? _buildEmptyState()
                    : _buildFileList(_filteredFiles),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip(null, 'All', Icons.folder_rounded),
            const SizedBox(width: 8),
            _buildCategoryChip(FileCategory.photo, 'Photos', Icons.image_rounded),
            const SizedBox(width: 8),
            _buildCategoryChip(FileCategory.video, 'Videos', Icons.videocam_rounded),
            const SizedBox(width: 8),
            _buildCategoryChip(FileCategory.document, 'Documents', Icons.description_rounded),
            const SizedBox(width: 8),
            _buildCategoryChip(FileCategory.data, 'Data', Icons.insert_drive_file_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(FileCategory? category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    final count = category == null
        ? _allFiles.length
        : _allFiles.where((f) => f.category == category).length;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppTheme.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
            child: Icon(
              _selectedCategory == null
                  ? Icons.folder_open_rounded
                  : _getCategoryIcon(_selectedCategory!),
              size: 48,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _selectedCategory == null
                ? 'No files received yet'
                : 'No ${_getCategoryName(_selectedCategory!).toLowerCase()} received',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Files are saved to:\n$_downloadPath',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(List<ReceivedFile> filteredFiles) {
    final groups = _getGroupedByDate(filteredFiles);
    final sortedKeys = groups.keys.toList();

    return RefreshIndicator(
      onRefresh: _loadFilesFromDisk,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final dateKey = sortedKeys[index];
          final files = groups[dateKey]!;
          return _buildDateGroup(dateKey, files);
        },
      ),
    );
  }

  Widget _buildDateGroup(String dateLabel, List<ReceivedFile> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        ...files.map((file) => _buildFileCard(file)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFileCard(ReceivedFile file) {
    final exists = File(file.filePath).existsSync();

    return GestureDetector(
      onTap: exists ? () => _openFile(file) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            _buildFileThumbnail(file, exists),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: exists ? AppTheme.textPrimary : AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatFileSize(file.size),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppTheme.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(file.receivedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (!exists)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'File not found',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: exists ? AppTheme.textMuted : AppTheme.border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileThumbnail(ReceivedFile file, bool exists) {
    if (file.isImage && exists) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(file.filePath),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFileIcon(file),
        ),
      );
    }
    return _buildFileIcon(file);
  }

  Widget _buildFileIcon(ReceivedFile file) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    switch (file.category) {
      case FileCategory.photo:
        bgColor = Colors.blue.withOpacity(0.15);
        iconColor = Colors.blue;
        icon = Icons.image_rounded;
        break;
      case FileCategory.video:
        bgColor = Colors.purple.withOpacity(0.15);
        iconColor = Colors.purple;
        icon = Icons.videocam_rounded;
        break;
      case FileCategory.document:
        bgColor = Colors.orange.withOpacity(0.15);
        iconColor = Colors.orange;
        icon = Icons.description_rounded;
        break;
      case FileCategory.data:
        bgColor = Colors.grey.withOpacity(0.15);
        iconColor = Colors.grey;
        icon = Icons.insert_drive_file_rounded;
        break;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }

  IconData _getCategoryIcon(FileCategory category) {
    return switch (category) {
      FileCategory.photo => Icons.image_rounded,
      FileCategory.video => Icons.videocam_rounded,
      FileCategory.document => Icons.description_rounded,
      FileCategory.data => Icons.insert_drive_file_rounded,
    };
  }

  String _getCategoryName(FileCategory category) {
    return switch (category) {
      FileCategory.photo => 'Photos',
      FileCategory.video => 'Videos',
      FileCategory.document => 'Documents',
      FileCategory.data => 'Data files',
    };
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDateTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  void _openFile(ReceivedFile file) async {
    try {
      await OpenFile.open(file.filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
