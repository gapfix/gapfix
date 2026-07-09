import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gapfix/core/auth_provider.dart';
import 'package:gapfix/core/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final Map<String, ChatContact> _contactsMap = {};
  StreamSubscription? _bookingsSub;
  StreamSubscription? _chatsSub;
  bool _isLoading = true;

  // Specify the 'gapfix' database ID
  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'gapfix');

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _chatsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentUid = user.uid;
    
    // We try to get profile but don't block everything on it
    final userProfile = await ref.read(userProfileProvider.future).catchError((_) => null);
    final isTutor = userProfile?.role == 'Tutor';

    // 1. Load from RTDB Bookings
    final bookingsRef = FirebaseDatabase.instance.ref('Bookings');
    final queryField = isTutor ? 'tutorId' : 'studentId';

    _bookingsSub = bookingsRef.orderByChild(queryField).equalTo(currentUid).onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final booking = value as Map;
          final contactId = isTutor ? booking['studentId'] : booking['tutorId'];
          if (contactId != null) {
            _addOrUpdateContact(contactId as String, isContactTutor: !isTutor);
          }
        });
      }
      if (mounted) setState(() => _isLoading = false);
    }, onError: (e) {
       debugPrint('RTDB Error: $e');
       if (mounted) setState(() => _isLoading = false);
    });

    // 2. Load from Firestore Chats (using 'gapfix' DB)
    _chatsSub = _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        for (var id in participants) {
          if (id != currentUid) {
            int unread = 0;
            
            // Handle unread counts
            final ucc = data['unreadChatCount'];
            if (ucc is Map && ucc[currentUid] is num) {
              unread = (ucc[currentUid] as num).toInt();
            } else if (data['unreadChatCount.$currentUid'] is num) {
              unread = (data['unreadChatCount.$currentUid'] as num).toInt();
            }
            
            _addOrUpdateContact(
              id, 
              isContactTutor: !isTutor, 
              chatId: doc.id, 
              lastMessage: data['lastMessage'],
              unreadCount: unread,
            );
          }
        }
      }
      if (mounted) setState(() => _isLoading = false);
    }, onError: (e) {
      debugPrint('Firestore Error: $e');
      if (mounted) setState(() => _isLoading = false);
    });
    
    // Safety timeout
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    });
  }

  void _addOrUpdateContact(String id, {required bool isContactTutor, String? chatId, String? lastMessage, int? unreadCount}) {
    if (!_contactsMap.containsKey(id)) {
      _contactsMap[id] = ChatContact(id: id, isTutor: isContactTutor);
    }
    if (chatId != null) _contactsMap[id]!.chatId = chatId;
    if (lastMessage != null) _contactsMap[id]!.lastMessage = lastMessage;
    if (unreadCount != null) _contactsMap[id]!.unreadCount = unreadCount;
    
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _contactsMap.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final contacts = _contactsMap.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.messageCircle, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No conversations yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ContactTile(contact: contact);
              },
            ),
    );
  }
}

class ChatContact {
  final String id;
  final bool isTutor;
  String? chatId;
  String? lastMessage;
  int unreadCount;

  ChatContact({required this.id, required this.isTutor, this.chatId, this.lastMessage, this.unreadCount = 0});
}

class ContactTile extends ConsumerWidget {
  final ChatContact contact;

  const ContactTile({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _fetchUserDetails(contact.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
          return const Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(title: Text('Loading...')),
          );
        }

        final userData = snapshot.data;
        final name = userData?['name'] ?? 'Unknown User';
        final image = userData?['imageResourceLink'] as String?;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: image != null ? CachedNetworkImageProvider(image) : null,
              child: image == null ? const Icon(LucideIcons.user) : null,
            ),
            title: Row(
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                if (contact.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: Text('${contact.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
              ],
            ),
            subtitle: Text(contact.lastMessage ?? (contact.isTutor ? 'Tutor' : 'Student'), 
              maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () => _showContactMenu(context, name, contact.id, contact.isTutor),
          ),
        );
      },
    );
  }

  Future<Map<dynamic, dynamic>?> _fetchUserDetails(String id) async {
    var snap = await FirebaseDatabase.instance.ref('Users/Student/$id').get();
    if (snap.exists) return snap.value as Map;
    
    snap = await FirebaseDatabase.instance.ref('Users/Tutor/$id').get();
    if (snap.exists) return snap.value as Map;
    
    return null;
  }

  void _showContactMenu(BuildContext context, String name, String contactId, bool isTutor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(LucideIcons.messageCircle, color: AppTheme.primary),
                title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed(
                    'chat-detail',
                    extra: {
                      'otherUserId': contactId,
                      'otherUserName': name,
                    },
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(LucideIcons.fileText, color: AppTheme.primary),
                title: const Text('Homeworks', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed(
                    'homeworks',
                    extra: {
                      'otherUserId': contactId,
                      'otherUserName': name,
                      'isStudent': !isTutor,
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
