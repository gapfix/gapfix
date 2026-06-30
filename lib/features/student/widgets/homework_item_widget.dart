import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/firestore_message_model.dart';
import '../../../models/archive_item_model.dart';

class HomeworkItemWidget extends StatelessWidget {
  final FirestoreMessage homework;
  final String chatId;
  final String otherUserId;

  const HomeworkItemWidget({
    super.key,
    required this.homework,
    required this.chatId,
    required this.otherUserId,
  });

  Future<void> _uploadSolution(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final isPdf = result.files.single.extension?.toLowerCase() == 'pdf';
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uploading solution...")),
        );

        final cloudinary = CloudinaryPublic('dbugqpl3m', 'ml_default', cache: false);
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            filePath,
            folder: 'Solutions/$chatId',
            resourceType: isPdf ? CloudinaryResourceType.Auto : CloudinaryResourceType.Image,
          ),
        );

        final url = response.secureUrl;

        await FirebaseFirestore.instance
            .collection("chats")
            .doc(chatId)
            .collection("messages")
            .doc(homework.documentId)
            .update({
          "solutionUrl": url,
          "homeworkStatus": "done",
        });

        await FirebaseFirestore.instance.collection("chats").doc(chatId).set({
          "lastMessage": "[Solution Uploaded]",
          "lastMessageType": "solution",
          "lastMessageTime": FieldValue.serverTimestamp(),
          "unreadCount.$otherUserId": FieldValue.increment(1),
          "unreadHomeworkCount.$otherUserId": FieldValue.increment(1),
        }, SetOptions(merge: true));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Solution uploaded")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    }
  }

  Future<void> _markFailed(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .doc(homework.documentId)
          .update({"homeworkStatus": "failed"});

      await FirebaseFirestore.instance.collection("chats").doc(chatId).set({
        "lastMessage": "[Couldn't do homework]",
        "lastMessageTime": FieldValue.serverTimestamp(),
        "unreadCount.$otherUserId": FieldValue.increment(1),
        "unreadHomeworkCount.$otherUserId": FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e")),
        );
      }
    }
  }

  Future<void> _archiveHomework(BuildContext context) async {
    if (homework.fileUrl == null) return;

    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final title = homework.text ?? "Archived Homework";
      final subject = homework.subject ?? "General";
      
      final safeTitle = title.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
      final safeSubject = subject.replaceAll(RegExp(r'[.#$\[\]/]'), '_');

      final archiveItem = ArchiveItemModel(
        documentId: homework.documentId,
        studentId: currentUserId,
        subject: safeSubject,
        fileUrl: homework.fileUrl,
        fileName: safeTitle,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        reviewed: false,
      );

      await FirebaseDatabase.instance
          .ref("Users/Student/$currentUserId/Archives/$safeSubject/$safeTitle")
          .set(archiveItem.toJson());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Added to Archive")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Archive failed: $e")),
        );
      }
    }
  }

  void _viewFile(BuildContext context, String? url, String? title) {
    if (url == null) return;
    if (url.toLowerCase().contains(".pdf") || url.toLowerCase().contains("cloudinary.com")) {
      context.push('/pdf-viewer', extra: {'url': url, 'title': title ?? 'File Viewer'});
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: CachedNetworkImage(
                  imageUrl: url,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSolution = homework.solutionUrl != null;
    final isFailed = homework.homeworkStatus == 'failed';
    
    String subtitleText = "Click to view file";
    if (homework.lessonTimestamp != null && homework.lessonTimestamp != 0) {
      final date = DateTime.fromMillisecondsSinceEpoch(homework.lessonTimestamp!);
      subtitleText = DateFormat("EEE, MMM dd @ HH:mm").format(date);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE9ECEF)),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              onTap: () => _viewFile(context, homework.fileUrl, homework.text),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: homework.fileUrl?.toLowerCase().endsWith('.pdf') == true
                          ? Colors.red
                          : const Color(0xFF00B894),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (homework.subject ?? "General").toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF00B894),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          homework.text ?? "Untitled Assignment",
                          style: const TextStyle(
                            color: Color(0xFF2D3436),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitleText,
                          style: const TextStyle(
                            color: Color(0xFF636E72),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF636E72)),
                ],
              ),
            ),
            if (!hasSolution && !isFailed) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _uploadSolution(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2ECC71),
                        side: const BorderSide(color: Color(0xFF2ECC71)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("I did it! Upload pic", style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _markFailed(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE74C3C),
                        side: const BorderSide(color: Color(0xFFE74C3C)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Couldn't do it", style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
            if (hasSolution) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _viewFile(context, homework.solutionUrl, "Solution"),
                    icon: const Icon(Icons.assignment_outlined, size: 14),
                    label: const Text("View solution picture", style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3498DB),
                      side: const BorderSide(color: Color(0xFF3498DB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  _buildFeedbackBadge(homework.tutorFeedback),
                ],
              ),
            ],
            if (isFailed) ...[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: _buildStatusBadge("Couldn't do it", Colors.red),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _archiveHomework(context),
                icon: const Icon(Icons.archive_outlined, size: 16),
                label: const Text("Add to Archive", style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00B894),
                  side: const BorderSide(color: Color(0xFF00B894)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackBadge(String? feedback) {
    if (feedback == null) {
      return _buildStatusBadge("Awaiting Review", Colors.orange);
    }
    final isCorrect = feedback.toLowerCase() == 'correct';
    return _buildStatusBadge(
      isCorrect ? "Correct" : "Incorrect",
      isCorrect ? Colors.green : Colors.red,
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}