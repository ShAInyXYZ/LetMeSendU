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

  FileTransferProgress({
    required this.fileId,
    required this.fileName,
    required this.totalBytes,
    this.receivedBytes = 0,
    this.status = TransferStatus.pending,
  });

  double get progress =>
      totalBytes > 0 ? receivedBytes / totalBytes : 0.0;
}
