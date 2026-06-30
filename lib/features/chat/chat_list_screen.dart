import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gapfix/core/auth_provider.dart';
import 'package:gapfix/core/theme.dart';
import 'package:gapfix/models/user_model.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    if (userProfile == null) return const Center(child: CircularProgressIndicator.adaptive());

    final isTutor = userProfile.role == 'Tutor';
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    
    // We fetch bookings to find who we have classes with
    final bookingsRef = FirebaseDatabase.instance.ref('Bookings');
    final queryField = isTutor ? 'tutorId' : 'studentId';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTutor ? 'My Students' : 'My Tutors'),
      ),
      body: StreamBuilder(
        stream: bookingsRef.orderByChild(queryField).equalTo(currentUid).onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    isTutor ? 'No students yet' : 'No tutors yet',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final Set<String> contactIds = {};
          
          data.forEach((key, value) {
            final booking = value as Map;
            final contactId = isTutor ? booking['studentId'] : booking['tutorId'];
            if (contactId != null) contactIds.add(contactId as String);
          });

          if (contactIds.isEmpty) {
            return const Center(child: Text('No contacts found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contactIds.length,
            itemBuilder: (context, index) {
              final contactId = contactIds.elementAt(index);
              return ContactTile(
                contactId: contactId, 
                isContactTutor: !isTutor,
              );
            },
          );
        },
      ),
    );
  }
}

class ContactTile extends ConsumerWidget {
  final String contactId;
  final bool isContactTutor;

  const ContactTile({
    super.key,
    required this.contactId,
    required this.isContactTutor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactType = isContactTutor ? 'Tutor' : 'Student';
    final userRef = FirebaseDatabase.instance.ref('Users/$contactType/$contactId');

    return FutureBuilder(
      future: userRef.get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.value == null) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.value as Map;
        final name = userData['name'] ?? 'Unknown';
        final image = userData['imageResourceLink'] as String?;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: image != null ? CachedNetworkImageProvider(image) : null,
              child: image == null ? const Icon(Icons.person) : null,
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isContactTutor ? 'Tutor' : 'Student'),
            trailing: const Icon(Icons.more_vert),
            onTap: () => _showContactMenu(context, name, contactId),
          ),
        );
      },
    );
  }

  void _showContactMenu(BuildContext context, String name, String contactId) {
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
                leading: const Icon(Icons.chat_bubble_outline, color: AppTheme.primary),
                title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to Chat Detail
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.assignment_outlined, color: AppTheme.primary),
                title: const Text('Homeworks', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to Homeworks Screen
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
