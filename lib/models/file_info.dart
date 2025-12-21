class FileInfo {
  final String id;
  final String fileName;
  final int size;
  final String fileType;
  final String? sha256;
  final String? preview;
  final FileMetadata? metadata;

  const FileInfo({
    required this.id,
    required this.fileName,
    required this.size,
    required this.fileType,
    this.sha256,
    this.preview,
    this.metadata,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      size: json['size'] as int,
      fileType: json['fileType'] as String,
      sha256: json['sha256'] as String?,
      preview: json['preview'] as String?,
      metadata: json['metadata'] != null
          ? FileMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'size': size,
      'fileType': fileType,
      if (sha256 != null) 'sha256': sha256,
      if (preview != null) 'preview': preview,
      if (metadata != null) 'metadata': metadata!.toJson(),
    };
  }
}

class FileMetadata {
  final int? modified;
  final int? accessed;

  const FileMetadata({this.modified, this.accessed});

  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(
      modified: json['modified'] as int?,
      accessed: json['accessed'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (modified != null) 'modified': modified,
      if (accessed != null) 'accessed': accessed,
    };
  }
}
