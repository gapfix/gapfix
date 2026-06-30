import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final String type; // 'text', 'homework', 'image'
  final String? fileUrl;
  final Map<String, dynamic>? metadata;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.type,
    this.fileUrl,
    this.metadata,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] as Timestamp,
      type: data['type'] ?? 'text',
      fileUrl: data['fileUrl'] as String?,
      metadata: data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'type': type,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (metadata != null) ...metadata!,
    };
  }
}
