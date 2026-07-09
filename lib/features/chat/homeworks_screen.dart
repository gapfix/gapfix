import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:intl/intl.dart';
import '../../models/firestore_message_model.dart';
import '../../models/booking_model.dart';
import '../student/widgets/homework_item_widget.dart';
import 'package:flutter/foundation.dart';
import '../../core/toast_utils.dart';
import '../../core/theme.dart';
import '../../core/auth_provider.dart';




class HomeworksScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final bool isStudent;

  const HomeworksScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.isStudent,
  });

  @override
  ConsumerState<HomeworksScreen> createState() => _HomeworksScreenState();
}

class _HomeworksScreenState extends ConsumerState<HomeworksScreen> {
  String? _chatId;
  bool _isSearching = true;

  // Use the 'gapfix' database ID
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: "gapfix");

  @override
  void initState() {
    super.initState();
    _getChatId();
  }

  Future<void> _getChatId() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        if (mounted) setState(() => _isSearching = false);
        return;
      }

      // 1. Try finding by participants array
      final query = await _db
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in query.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(widget.otherUserId)) {
          if (mounted) {
            setState(() {
              _chatId = doc.id;
              _isSearching = false;
            });
            _clearUnread(doc.id, currentUserId);
          }
          return;
        }
      }
      
      // 2. Fallback: Check for UID1_UID2 ID format
      final ids = [currentUserId, widget.otherUserId];
      ids.sort();
      final potentialId = "${ids[0]}_${ids[1]}";
      final docSnap = await _db.collection('chats').doc(potentialId).get();
      if (docSnap.exists) {
        if (mounted) {
          setState(() {
            _chatId = potentialId;
            _isSearching = false;
          });
          _clearUnread(potentialId, currentUserId);
        }
        return;
      }
    } catch (e) {
      debugPrint('Error getting chatId: $e');
    }

    if (mounted) {
      setState(() => _isSearching = false);
    }
  }

  void _clearUnread(String chatId, String currentUserId) {
    _db.collection('chats').doc(chatId).update({
      'unreadHomeworkCount.$currentUserId': 0,
      'unreadCount.$currentUserId': 0,
    }).catchError((e) {
       _db.collection('chats').doc(chatId).set({
         'unreadHomeworkCount': { currentUserId: 0 },
         'unreadCount': { currentUserId: 0 },
       }, SetOptions(merge: true));
    });
  }

  void _showAssignHomeworkDialog() {
    String title = '';
    String? selectedSubject;
    BookingModel? selectedLesson;
    String? filePath;
    String? fileName;
    Uint8List? fileBytes;
    bool isUploading = false;
    final titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const Text('Add Homework', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Homework Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                FutureBuilder<List<BookingModel>>(
                  future: _fetchRelatedBookings(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    final allRelatedBookings = snapshot.data!;
                    if (allRelatedBookings.isEmpty) return const Text('No lessons found to assign homework to.');
                    
                    final subjects = allRelatedBookings.map((b) => b.subject).toSet().toList()..sort();
                    
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedSubject,
                          hint: const Text('Select Subject'),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              selectedSubject = val;
                              selectedLesson = null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        if (selectedSubject != null)
                          DropdownButtonFormField<BookingModel>(
                            value: selectedLesson,
                            hint: const Text('Select Lesson'),
                            isExpanded: true,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: allRelatedBookings
                                .where((b) => b.subject == selectedSubject)
                                .map((b) {
                                  final date = DateTime.fromMillisecondsSinceEpoch(b.timestamp);
                                  return DropdownMenuItem(
                                    value: b,
                                    child: Text(DateFormat('MMM dd, yyyy @ HH:mm').format(date)),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              setModalState(() => selectedLesson = val);
                            },
                          ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                      withData: true,
                    );
                    if (result != null) {
                      setModalState(() {
                        filePath = result.files.single.path;
                        fileName = result.files.single.name;
                        fileBytes = result.files.single.bytes;
                      });
                    }
                  },
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.plus, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          fileName ?? 'Upload Image or PDF',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                if (isUploading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isEmpty || selectedSubject == null || selectedLesson == null || fileName == null) {
                          ToastUtils.show(context, 'Please fill all fields and attach a file', isError: true);
                          return;
                        }
                        
                        setModalState(() => isUploading = true);
                        try {
                          await _assignHomework(
                            title: titleController.text,
                            subject: selectedSubject!,
                            path: filePath,
                            bytes: fileBytes,
                            name: fileName!,
                            booking: selectedLesson!,
                          );
                          if (mounted) Navigator.pop(context);
                        } finally {
                          setModalState(() => isUploading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('SAVE HOMEWORK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<BookingModel>> _fetchRelatedBookings() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final snap = await FirebaseDatabase.instance.ref('Bookings').get();
    if (!snap.exists) return [];

    final minimumTimestamp = DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch;
    final data = snap.value as Map;
    final List<BookingModel> result = [];
    data.forEach((key, value) {
      final b = BookingModel.fromMap(key.toString(), value as Map);
      final isRelatedBooking =
          (b.tutorId == currentUserId && b.studentId == widget.otherUserId) ||
          (b.studentId == currentUserId && b.tutorId == widget.otherUserId);

      if (isRelatedBooking && b.timestamp > minimumTimestamp) {
        result.add(b);
      }
    });

    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  Future<void> _assignHomework({
    required String title,
    required String subject,
    String? path,
    Uint8List? bytes,
    required String name,
    required BookingModel booking,
  }) async {
    if (_chatId == null) return;
    try {
      final cloudinary = CloudinaryPublic('dbugqpl3m', 'ml_default', cache: false);
      CloudinaryResponse response;
      
      if (bytes != null && (kIsWeb || path == null)) {
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            bytes.toList(),
            identifier: name,
            folder: 'Homeworks/$_chatId',
          ),
        );
      } else if (path != null) {
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(path, folder: 'Homeworks/$_chatId'),
        );
      } else {
        throw Exception("No valid file data found to upload.");
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      await _db.collection('chats').doc(_chatId).collection('messages').add({
        'senderId': currentUserId,
        'receiverId': widget.otherUserId,
        'text': title,
        'subject': subject,
        'fileUrl': response.secureUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'homework',
        'homeworkStatus': 'pending',
        'lessonTimestamp': booking.timestamp,
        'chatId': _chatId,
      });

      await _db.collection('chats').doc(_chatId).update({
        'lastMessage': 'Assigned Homework: $subject',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'unreadHomeworkCount.${widget.otherUserId}': FieldValue.increment(1),
      });

      if (mounted) ToastUtils.show(context, 'Homework assigned successfully');
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).value;
    final isTutor = userProfile?.role.toLowerCase() == 'tutor';

    final title = widget.otherUserName.isEmpty || widget.otherUserName == 'Loading...' 
        ? 'Homeworks' 
        : 'Homeworks - ${widget.otherUserName}';

    if (_isSearching) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_chatId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: Text('No homework history found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final homeworks = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = (data['type'] as String?)?.toLowerCase();
            final status = data['homeworkStatus'];
            
            return type == 'homework' || 
                   type == 'solution' || 
                   type == 'assignment' || 
                   status != null;
          }).map((doc) {
            final msg = FirestoreMessage.fromFirestore(doc);
            msg.chatId = _chatId;
            return msg;
          }).toList();
          
          if (homeworks.isEmpty) {
            return _buildEmptyState();
          }

          homeworks.sort((a, b) => (b.timestamp?.toDate() ?? DateTime(0)).compareTo(a.timestamp?.toDate() ?? DateTime(0)));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            itemCount: homeworks.length,
            itemBuilder: (context, index) {
              final homework = homeworks[index];
              return HomeworkItemWidget(
                homework: homework,
                chatId: _chatId!,
                otherUserId: widget.otherUserId,
                isStudent: !isTutor,
              );
            },
          );
        },
      ),
      floatingActionButton: isTutor ? FloatingActionButton.extended(
        onPressed: _showAssignHomeworkDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('ASSIGN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.fileText, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No homeworks found', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
