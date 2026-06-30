import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/student_tutor_display_model.dart';
import '../../../models/firestore_message_model.dart';
import 'homework_item_widget.dart';

void showHomeworkBottomSheet(BuildContext context, StudentTutorDisplayModel tutor) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => HomeworkBottomSheet(tutor: tutor),
  );
}

class HomeworkBottomSheet extends StatefulWidget {
  final StudentTutorDisplayModel tutor;

  const HomeworkBottomSheet({super.key, required this.tutor});

  @override
  State<HomeworkBottomSheet> createState() => _HomeworkBottomSheetState();
}

class _HomeworkBottomSheetState extends State<HomeworkBottomSheet> {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late String _chatId;

  @override
  void initState() {
    super.initState();
    if (widget.tutor.chatId != null && widget.tutor.chatId!.isNotEmpty) {
      _chatId = widget.tutor.chatId!;
    } else {
      final ids = [_currentUserId, widget.tutor.uid!];
      ids.sort();
      _chatId = "${ids[0]}_${ids[1]}";
    }
    
    _clearUnread();
  }

  void _clearUnread() {
    FirebaseFirestore.instance.collection("chats").doc(_chatId).update({
      "unreadHomeworkCount.$_currentUserId": FieldValue.arrayRemove([]), // Using a trick to clear, or just set to 0
    }).catchError((e) {
      // In case it's a nested field and doesn't exist yet, we can try a merge set or ignore
      FirebaseFirestore.instance.collection("chats").doc(_chatId).set({
        "unreadHomeworkCount": {
          _currentUserId: 0
        }
      }, SetOptions(merge: true));
    });
    
    // Better way:
     FirebaseFirestore.instance.collection("chats").doc(_chatId).update({
      "unreadHomeworkCount.$_currentUserId": 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Homeworks",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("chats")
                    .doc(_chatId)
                    .collection("messages")
                    .where("type", isEqualTo: "homework")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Text("Something went wrong");
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final homeworks = snapshot.data!.docs
                      .map((doc) => FirestoreMessage.fromFirestore(doc))
                      .toList();

                  homeworks.sort((a, b) {
                    final t1 = a.timestamp?.millisecondsSinceEpoch ?? 0;
                    final t2 = b.timestamp?.millisecondsSinceEpoch ?? 0;
                    return t2.compareTo(t1);
                  });

                  if (homeworks.isEmpty) {
                    return const Center(child: Text("No homeworks found"));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: homeworks.length,
                    itemBuilder: (context, index) {
                      return HomeworkItemWidget(
                        homework: homeworks[index],
                        chatId: _chatId,
                        otherUserId: widget.tutor.uid!,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}