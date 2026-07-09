import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
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
  
  // Set this to 'true' if you want to force the button to show up during testing
  bool _isTutor = false; 
  bool _isLoading = true;

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
    
    _checkRole();
    _clearUnread();
  }

  Future<void> _checkRole() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      
      // Print current user ID to console to verify who is logged in
      debugPrint('HomeworkSheet: Checking role for UID: $uid');
      
      final snap = await FirebaseDatabase.instance.ref('Users/Tutor/$uid').get();
      
      debugPrint('HomeworkSheet: RTDB path exists? ${snap.exists}');
      debugPrint('HomeworkSheet: RTDB path value: ${snap.value}');

      if (mounted) {
        setState(() {
          // If the path check fails in your environment, change this to: _isTutor = true; to force it
          _isTutor = snap.exists; 
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('HomeworkSheet: Error checking role: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearUnread() {
    FirebaseFirestore.instance.collection("chats").doc(_chatId).update({
      "unreadHomeworkCount.$_currentUserId": 0,
    }).catchError((e) {
      FirebaseFirestore.instance.collection("chats").doc(_chatId).set({
        "unreadHomeworkCount": {
          _currentUserId: 0
        }
      }, SetOptions(merge: true));
    });
  }

  void _showAddHomeworkDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Add Homework",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Homework Name',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Select Subject',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  items: const [],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Select Lesson',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  items: const [],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, color: Color(0xFF00B894)),
                  label: const Text("Upload Homework File", style: TextStyle(color: Color(0xFF00B894))),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: Color(0xFF00B894)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B894),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Save Homework", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Homeworks",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                // Button displays if _isTutor is evaluated to true
                if (_isTutor)
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF00B894), size: 28),
                    onPressed: _showAddHomeworkDialog,
                  ),
              ],
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
                        isStudent: !_isTutor, 
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