import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/student_tutor_display_model.dart';
import 'homework_bottom_sheet.dart';

class TutorCardWidget extends StatefulWidget {
  final StudentTutorDisplayModel tutor;
  final VoidCallback onDelete;

  const TutorCardWidget({
    super.key,
    required this.tutor,
    required this.onDelete,
  });

  @override
  State<TutorCardWidget> createState() => _TutorCardWidgetState();
}

class _TutorCardWidgetState extends State<TutorCardWidget> {
  @override
  Widget build(BuildContext context) {
    final tutor = widget.tutor;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                tutor.isExpanded = !tutor.isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: tutor.profileImage != null && tutor.profileImage!.isNotEmpty
                        ? NetworkImage(tutor.profileImage!)
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: tutor.profileImage == null || tutor.profileImage!.isEmpty
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              tutor.name ?? "Loading...",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                            if (tutor.unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  '${tutor.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          tutor.email ?? "",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.rotate(
                    angle: tutor.isExpanded ? 3.14159 / 2 : -3.14159 / 2,
                    child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          if (tutor.isExpanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _ActionItem(
                    icon: Icons.chat_bubble_outline,
                    label: "Chats",
                    badgeCount: tutor.unreadChatCount,
                    onTap: () {
                      context.push('/chat', extra: {
                        'userId': tutor.uid,
                        'userName': tutor.name,
                        'chatId': tutor.chatId,
                      });
                    },
                  ),
                  _ActionItem(
                    icon: Icons.book_outlined,
                    label: "Homeworks",
                    badgeCount: tutor.unreadHomeworkCount,
                    onTap: () {
                      // FIXED: Reverted back to the original function structure.
                      // The bottom sheet now checks the database directly to verify the tutor role!
                      showHomeworkBottomSheet(context, tutor);
                    },
                  ),
                  if (tutor.canDelete)
                    _ActionItem(
                      icon: Icons.delete_outline,
                      label: "Delete",
                      color: Colors.red,
                      onTap: widget.onDelete,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;
  final Color? color;

  const _ActionItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color ?? const Color(0xFF00B894), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: color ?? const Color(0xFF2D3436),
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color ?? const Color(0xFF00B894),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}