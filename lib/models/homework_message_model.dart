import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkMessageModel {
  final String documentId;
  final String? chatId;
  final String? senderId;
  final String? receiverId;
  final String? text;
  final String? type; // should be 'homework'
  final DateTime? timestamp;
  final int lessonTimestamp;
  final String? subject;
  final String? fileUrl;
  final String? homeworkStatus; // 'done', 'failed', 'awaiting_review', etc.
  final String? solutionUrl;
  final String? tutorFeedback;

  HomeworkMessageModel({
    required this.documentId,
    this.chatId,
    this.senderId,
    this.receiverId,
    this.text,
    this.type,
    this.timestamp,
    this.lessonTimestamp = 0,
    this.subject,
    this.fileUrl,
    this.homeworkStatus,
    this.solutionUrl,
    this.tutorFeedback,
  });

  factory HomeworkMessageModel.fromFirestore(DocumentSnapshot doc, String chatId) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return HomeworkMessageModel(
      documentId: doc.id,
      chatId: chatId,
      senderId: map['senderId'] as String?,
      receiverId: map['receiverId'] as String?,
      text: map['text'] as String?,
      type: map['type'] as String?,
      timestamp: map['timestamp'] != null ? (map['timestamp'] as Timestamp).toDate() : null,
      lessonTimestamp: map['lessonTimestamp'] ?? 0,
      subject: map['subject'] as String?,
      fileUrl: map['fileUrl'] as String?,
      homeworkStatus: map['homeworkStatus'] as String?,
      solutionUrl: map['solutionUrl'] as String?,
      tutorFeedback: map['tutorFeedback'] as String?,
    );
  }
}
