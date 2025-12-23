import 'file_info.dart';

class TransferSession {
  final String sessionId;
  final Map<String, FileInfo> files;
  final Map<String, String> tokens;
  final String senderIp;
  final DateTime createdAt;
  TransferStatus status;

  TransferSession({
    required this.sessionId,
    required this.files,
    required this.tokens,
    required this.senderIp,
    DateTime? createdAt,
    this.status = TransferStatus.pending,
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalSize => files.values.fold(0, (sum, f) => sum + f.size);
  int get fileCount => files.length;
}

enum TransferStatus {
  pending,
  inProgress,
  completed,
  cancelled,
  failed,
}

class FileTransferProgress {
  final String fileId;
  final String fileName;
  final int totalBytes;
  int receivedBytes;
  TransferStatus status;
  String? filePath;

  FileTransferProgress({
    required this.fileId,
    required this.fileName,
    required this.totalBytes,
    this.receivedBytes = 0,
    this.status = TransferStatus.pending,
    this.filePath,
  });

  double get progress =>
      totalBytes > 0 ? receivedBytes / totalBytes : 0.0;
}

enum FileCategory { photo, video, document, data }

class ReceivedFile {
  final String fileName;
  final String filePath;
  final int size;
  final DateTime receivedAt;

  ReceivedFile({
    required this.fileName,
    required this.filePath,
    required this.size,
    required this.receivedAt,
  });

  String get extension => fileName.toLowerCase().split('.').last;

  bool get isImage {
    const exts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif'];
    return exts.contains(extension);
  }

  bool get isVideo {
    const exts = ['mp4', 'mkv', 'avi', 'mov', 'webm', 'flv', '3gp'];
    return exts.contains(extension);
  }

  bool get isDocument {
    const exts = ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'];
    return exts.contains(extension);
  }

  FileCategory get category {
    if (isImage) return FileCategory.photo;
    if (isVideo) return FileCategory.video;
    if (isDocument) return FileCategory.document;
    return FileCategory.data;
  }

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'filePath': filePath,
        'size': size,
        'receivedAt': receivedAt.toIso8601String(),
      };

  factory ReceivedFile.fromJson(Map<String, dynamic> json) => ReceivedFile(
        fileName: json['fileName'] as String,
        filePath: json['filePath'] as String,
        size: json['size'] as int,
        receivedAt: DateTime.parse(json['receivedAt'] as String),
      );
}
