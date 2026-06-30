class ArchiveModel {
  final String id;
  final String title;
  final String userId;
  final String subject;
  final String fileUrl;
  final String fileName;
  final int timestamp;
  final bool reviewed;

  ArchiveModel({
    required this.id,
    required this.title,
    required this.userId,
    required this.subject,
    required this.fileUrl,
    required this.fileName,
    required this.timestamp,
    this.reviewed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': id,
      'title': title,
      'studentId': userId,
      'subject': subject,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'timestamp': timestamp,
      'reviewed': reviewed,
    };
  }

  factory ArchiveModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return ArchiveModel(
      id: map['documentId'] ?? id,
      title: map['title'] ?? map['fileName'] ?? id,
      userId: map['userId'] ?? map['studentId'] ?? '',
      subject: map['subject'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      reviewed: map['reviewed'] ?? false,
    );
  }
}

class SubjectArchiveModel {
  final String subjectName;
  final int totalFiles;
  final int reviewedCount;

  SubjectArchiveModel({
    required this.subjectName,
    required this.totalFiles,
    required this.reviewedCount,
  });
}
