class DocumentModel {
  final int id;
  final int userId;
  final String title;
  final String originalFilename;
  final int fileSize;
  final DateTime uploadDate;
  final String downloadUrl;

  const DocumentModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.originalFilename,
    required this.fileSize,
    required this.uploadDate,
    required this.downloadUrl,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      originalFilename: json['original_filename'] as String,
      fileSize: json['file_size'] as int,
      uploadDate: DateTime.parse(json['upload_date'] as String),
      downloadUrl: json['download_url'] as String,
    );
  }

  /// Human-readable file size (e.g. "1.4 MB")
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
