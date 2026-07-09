import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/firestore_message_model.dart';
import '../../../models/archive_item_model.dart';
import '../../../core/theme.dart';
import '../../../core/file_opener.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class HomeworkItemWidget extends StatelessWidget {
  final FirestoreMessage homework;
  final String chatId;
  final String otherUserId;
  final bool isStudent;

  const HomeworkItemWidget({
    super.key,
    required this.homework,
    required this.chatId,
    required this.otherUserId,
    required this.isStudent,
  });

  FirebaseFirestore get _db => FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'gapfix');

  Future<void> _uploadSolution(BuildContext context) async {
    ScaffoldMessengerState? messenger;
    try {
      messenger = ScaffoldMessenger.of(context);
    } catch (_) {
      // No ScaffoldMessenger available — we'll skip snackbars but still upload
    }

    try {
      print('_uploadSolution called');
      
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
        withData: true,
      );

      if (result == null) {
        print('FilePicker returned null — user cancelled');
        return;
      }

      print('File picked: ${result.files.single.name}');
      print('Has bytes: ${result.files.single.bytes != null}');
      print('Bytes length: ${result.files.single.bytes?.length ?? 0}');
      print('Has path: ${result.files.single.path}');

      if (result.files.single.path == null && result.files.single.bytes == null) {
        print('ERROR: No path and no bytes — cannot upload');
        return;
      }

      final isPdf = result.files.single.extension?.toLowerCase() == 'pdf';

      messenger?.clearSnackBars();
      messenger?.showSnackBar(
        const SnackBar(content: Text("Uploading solution...")),
      );

      print('Starting Cloudinary upload...');
      final cloudinary = CloudinaryPublic('dbugqpl3m', 'ml_default', cache: false);

      CloudinaryResponse response;
      if (kIsWeb || result.files.single.path == null) {
        print('Using fromBytesData (web mode)');
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            result.files.single.bytes!.toList(),
            identifier: result.files.single.name,
            folder: 'Solutions/$chatId',
            resourceType: isPdf ? CloudinaryResourceType.Auto : CloudinaryResourceType.Image,
          ),
        );
      } else {
        print('Using fromFile (native mode)');
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            result.files.single.path!,
            folder: 'Solutions/$chatId',
            resourceType: isPdf ? CloudinaryResourceType.Auto : CloudinaryResourceType.Image,
          ),
        );
      }

      print('Cloudinary upload success: ${response.secureUrl}');
      final url = response.secureUrl;

      print('Updating Firestore document...');
      await _db
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .doc(homework.documentId)
          .update({
        "solutionUrl": url,
        "homeworkStatus": "awaiting_review",
        "tutorFeedback": FieldValue.delete(),
      });

      await _db.collection("chats").doc(chatId).set({
        "lastMessage": "[Solution Uploaded]",
        "lastMessageType": "solution",
        "lastMessageTimestamp": FieldValue.serverTimestamp(),
        "unreadChatCount.$otherUserId": FieldValue.increment(1),
        "unreadHomeworkCount.$otherUserId": FieldValue.increment(1),
      }, SetOptions(merge: true));

      print('Solution uploaded successfully!');
      messenger?.clearSnackBars();
      messenger?.showSnackBar(
        const SnackBar(content: Text("Solution uploaded")),
      );
    } catch (e, stackTrace) {
      print('Upload failed: $e');
      print('Stack trace: $stackTrace');
      messenger?.clearSnackBars();
      messenger?.showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  Future<void> _markFailed(BuildContext context) async {
    try {
      await _db
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .doc(homework.documentId)
          .update({"homeworkStatus": "failed"});

      await _db.collection("chats").doc(chatId).set({
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

  Future<void> _markFeedback(BuildContext context, String feedback) async {
     try {
       await _db
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .doc(homework.documentId)
          .update({"tutorFeedback": feedback});

       await _db.collection("chats").doc(chatId).set({
        "lastMessage": "[Homework Reviewed: $feedback]",
        "lastMessageTime": FieldValue.serverTimestamp(),
        "unreadCount.$otherUserId": FieldValue.increment(1),
        "unreadHomeworkCount.$otherUserId": FieldValue.increment(1),
      }, SetOptions(merge: true));
       
       if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Marked as $feedback")),
          );
        }
     } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update feedback: $e")),
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

  @override
  Widget build(BuildContext context) {
    final hasSolution = homework.solutionUrl != null && homework.solutionUrl!.isNotEmpty;
    final isFailed = homework.homeworkStatus == 'failed';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String subtitleText = "Click to view file";
    if (homework.lessonTimestamp != null && homework.lessonTimestamp != 0) {
      final date = DateTime.fromMillisecondsSinceEpoch(homework.lessonTimestamp!);
      subtitleText = DateFormat("EEE, MMM dd @ HH:mm").format(date);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => FileOpener.openFile(context, homework.fileUrl!, title: homework.text),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F2F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.fileText,
                      color: AppTheme.primary,
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
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          homework.text ?? "Untitled Assignment",
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF2D3436),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : const Color(0xFF636E72),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
                ],
              ),
            ),
            
            // Student Actions
            if (isStudent && (!hasSolution || homework.tutorFeedback?.toLowerCase() == 'incorrect') && !isFailed) ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _uploadSolution(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Color(0xFF2ECC71)),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("I did it! Upload pic", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _markFailed(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Color(0xFFE74C3C)),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Couldn't do it", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],

            // Solution & Feedback
            if (hasSolution) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),
              if (isStudent) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => FileOpener.openFile(context, homework.solutionUrl!, title: "Solution"),
                      icon: const Icon(LucideIcons.fileText, size: 14),
                      label: const Text("View solution", style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3498DB),
                        side: const BorderSide(color: Color(0xFF3498DB)),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    _buildFeedbackBadge(homework.tutorFeedback),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => FileOpener.openFile(context, homework.solutionUrl!, title: "Solution"),
                        icon: const Icon(LucideIcons.fileText, size: 14),
                        label: const Text("View solution", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3498DB),
                          side: const BorderSide(color: Color(0xFF3498DB)),
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (homework.tutorFeedback == null || homework.tutorFeedback!.isEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _markFeedback(context, "correct"),
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                            tooltip: "Right",
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                          IconButton(
                            onPressed: () => _markFeedback(context, "incorrect"),
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            tooltip: "Wrong",
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      )
                    ] else ...[
                      _buildFeedbackBadge(homework.tutorFeedback),
                    ],
                  ],
                ),
              ],
            ],

            if (isFailed && !hasSolution) ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFEEEEEE)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _buildStatusBadge("Couldn't do it", Colors.red),
              ),
            ],

            if (isStudent) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _archiveHomework(context),
                  icon: const Icon(LucideIcons.archive, size: 16),
                  label: const Text("Add to Archive", style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackBadge(String? feedback) {
    if (feedback == null || feedback.isEmpty) {
      return _buildStatusBadge("Awaiting...", Colors.orange);
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
