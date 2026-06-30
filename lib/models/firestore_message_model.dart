import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreMessage {
  String? senderId;
  String? receiverId;
  String? text;
  Timestamp? timestamp;
  String? type; // e.g., "text", "homework"
  String? fileUrl;
  String? documentId; // This is set after fetching from Firestore, not part of the stored doc
  String? homeworkStatus; // e.g., "pending", "done", "failed"
  int? lessonTimestamp; // Using int for long from Java
  String? subject;
  String? solutionUrl;
  String? tutorFeedback;
  String? chatId;

  FirestoreMessage({
    this.senderId,
    this.receiverId,
    this.text,
    this.timestamp,
    this.type,
    this.fileUrl,
    this.documentId,
    this.homeworkStatus,
    this.lessonTimestamp,
    this.subject,
    this.solutionUrl,
    this.tutorFeedback,
    this.chatId,
  });

  factory FirestoreMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FirestoreMessage(
      senderId: data['senderId'] as String?,
      receiverId: data['receiverId'] as String?,
      text: data['text'] as String?,
      timestamp: data['timestamp'] as Timestamp?,
      type: data['type'] as String?,
      fileUrl: data['fileUrl'] as String?,
      documentId: doc.id, // Set the document ID here
      homeworkStatus: data['homeworkStatus'] as String?,
      lessonTimestamp: data['lessonTimestamp'] as int?,
      subject: data['subject'] as String?,
      solutionUrl: data['solutionUrl'] as String?,
      tutorFeedback: data['tutorFeedback'] as String?,
      chatId: data['chatId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'type': type,
      'fileUrl': fileUrl,
      'homeworkStatus': homeworkStatus,
      'lessonTimestamp': lessonTimestamp,
      'subject': subject,
      'solutionUrl': solutionUrl,
      'tutorFeedback': tutorFeedback,
      'chatId': chatId,
    };
  }
}