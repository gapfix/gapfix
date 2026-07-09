import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../core/auth_provider.dart';
import '../../core/toast_utils.dart';
import '../../core/file_opener.dart';
import '../../models/firestore_message_model.dart';
import 'package:flutter/foundation.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _chatId;
  bool _isSearching = true;
  
  // Use the 'gapfix' database ID
  FirebaseFirestore get _db => FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'gapfix');

  @override
  void initState() {
    super.initState();
    _getOrCreateChatId();
  }

  Future<void> _getOrCreateChatId() async {
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

      // 3. Create new chat if not found
      final newChatDoc = await _db.collection('chats').add({
        'participants': [currentUserId, widget.otherUserId],
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'unreadChatCount': {
          currentUserId: 0,
          widget.otherUserId: 0,
        },
        'unreadHomeworkCount': {
          currentUserId: 0,
          widget.otherUserId: 0,
        },
      });

      if (mounted) {
        setState(() {
          _chatId = newChatDoc.id;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting chat: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _clearUnread(String chatId, String currentUserId) {
    _db.collection('chats').doc(chatId).update({
      'unreadChatCount.$currentUserId': 0,
      'unreadCount.$currentUserId': 0,
    }).catchError((e) {
       _db.collection('chats').doc(chatId).set({
         'unreadChatCount': { currentUserId: 0 },
         'unreadCount': { currentUserId: 0 },
       }, SetOptions(merge: true));
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    await _db.collection('chats').doc(_chatId).collection('messages').add({
      'senderId': currentUserId,
      'receiverId': widget.otherUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    });

    await _db.collection('chats').doc(_chatId).update({
      'lastMessage': text,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'unreadChatCount.${widget.otherUserId}': FieldValue.increment(1),
    });
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result == null) {
        print('FilePicker returned null');
        return;
      }
      
      print('File picked: ${result.files.single.name}');
      print('Has bytes: ${result.files.single.bytes != null}');
      print('Has path: ${result.files.single.path != null}');

      if ((result.files.single.path != null || result.files.single.bytes != null) && _chatId != null) {
        final fileName = result.files.single.name;
        
        if (!mounted) return;
        ToastUtils.show(context, 'Uploading file...');

        final cloudinary = CloudinaryPublic('dbugqpl3m', 'ml_default', cache: false);
        
        CloudinaryResponse response;
        if (kIsWeb || result.files.single.path == null) {
          response = await cloudinary.uploadFile(
            CloudinaryFile.fromBytesData(
              result.files.single.bytes!.toList(),
              identifier: fileName,
              folder: 'Chats/$_chatId',
            ),
          );
        } else {
          response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              result.files.single.path!,
              folder: 'Chats/$_chatId',
            ),
          );
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        await _db.collection('chats').doc(_chatId).collection('messages').add({
          'senderId': currentUserId,
          'receiverId': widget.otherUserId,
          'text': fileName,
          'fileUrl': response.secureUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'file',
        });

        await _db.collection('chats').doc(_chatId).update({
          'lastMessage': 'Sent a file: $fileName',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'unreadChatCount.${widget.otherUserId}': FieldValue.increment(1),
        });
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Error: $e', isError: true);
    }
  }


  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).value;
    final isTutor = userProfile?.role.toLowerCase() == 'tutor';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _chatId == null
                    ? const Center(child: Text('Could not load chat.'))
                    : StreamBuilder<QuerySnapshot>(
                    stream: _db
                            .collection('chats')
                            .doc(_chatId)
                            .collection('messages')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                          // Filter out homework and solution messages from chat detail
                          final docs = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final type = (data['type'] as String?)?.toLowerCase();
                            return type != 'homework' && type != 'assignment' && type != 'solution';
                          }).toList();

                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final msg = FirestoreMessage.fromFirestore(docs[index]);
                              final isMe = msg.senderId == FirebaseAuth.instance.currentUser?.uid;
                              
                              return ChatBubble(
                                message: msg,
                                isMe: isMe,
                              );
                            },
                          );
                        },
                      ),
          ),
          _buildMessageInput(isTutor),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isTutor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _pickAndSendFile,
              icon: const Icon(LucideIcons.paperclip, color: AppTheme.primary),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(LucideIcons.send),
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final FirestoreMessage message;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final type = message.type?.toLowerCase();
    
    if (type == 'homework' || type == 'assignment') {
       return _buildHomeworkBubble(context);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (type == 'file' || (message.fileUrl != null && type != 'homework'))
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.file, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => FileOpener.openFile(context, message.fileUrl!, title: message.text),
                      child: Text(
                        message.text ?? 'File',
                        style: TextStyle(
                          color: isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                message.text ?? '',
                style: TextStyle(
                  color: isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                ),
              ),
            if (message.timestamp != null) ...[
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(message.timestamp!.toDate()),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkBubble(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.indigo.withValues(alpha: 0.2) : Colors.indigo.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.fileText, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  message.subject ?? 'Homework',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message.text ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => FileOpener.openFile(context, message.fileUrl!, title: message.subject),
                icon: const Icon(LucideIcons.download, size: 18),
                label: const Text('View Homework'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  minimumSize: const Size(0, 40),
                ),
              ),
            ),
            if (message.timestamp != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormat('MMM d, HH:mm').format(message.timestamp!.toDate()),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}