class ArchiveItemModel {
  String? documentId;
  String? studentId;
  String? subject;
  String? fileUrl;
  String? fileName;
  int? timestamp; // long in Java maps to int in Dart for timestamps
  bool? reviewed;

  ArchiveItemModel({
    this.documentId,
    this.studentId,
    this.subject,
    this.fileUrl,
    this.fileName,
    this.timestamp,
    this.reviewed,
  });

  factory ArchiveItemModel.fromJson(Map<String, dynamic> json) {
    return ArchiveItemModel(
      documentId: json['documentId'] as String?,
      studentId: json['studentId'] as String?,
      subject: json['subject'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      timestamp: json['timestamp'] as int?,
      reviewed: json['reviewed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'studentId': studentId,
      'subject': subject,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'timestamp': timestamp,
      'reviewed': reviewed,
    };
  }
}