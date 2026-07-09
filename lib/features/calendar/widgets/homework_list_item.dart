import 'package:flutter/material.dart';
import 'package:gapfix/models/homework_message_model.dart';
import 'package:gapfix/core/file_opener.dart';

import 'package:gapfix/core/theme.dart';

class HomeworkListItem extends StatelessWidget {
  final HomeworkMessageModel homework;
  final VoidCallback onUploadSolution;
  final VoidCallback onCouldNotDoIt;
  final VoidCallback onArchive;
  final Function(String) onMarkFeedback;
  final bool isStudent;

  const HomeworkListItem({
    super.key,
    required this.homework,
    required this.onUploadSolution,
    required this.onCouldNotDoIt,
    required this.onArchive,
    required this.isStudent,
    required this.onMarkFeedback,
  });

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
        color: color.withValues(alpha: 0.1),
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

  @override
  Widget build(BuildContext context) {
    final hasSolution = homework.solutionUrl != null && homework.solutionUrl!.isNotEmpty;
    final isFailed = homework.homeworkStatus == 'failed';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final secondaryTextColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    homework.subject?.isNotEmpty == true ? homework.subject! : 'Homework',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isFailed && !hasSolution)
                  const Icon(Icons.error, color: Colors.red)
              ],
            ),
            const SizedBox(height: 8),
            Text(
              homework.text ?? 'No description provided.',
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (homework.fileUrl != null)
              OutlinedButton.icon(
                onPressed: () => FileOpener.openFile(context, homework.fileUrl!, title: homework.subject),
                icon: const Icon(Icons.attachment, size: 18),
                label: const Text('View Homework File', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                ),
              ),
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
                      icon: const Icon(Icons.file_present, size: 14),
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
                        icon: const Icon(Icons.file_present, size: 14),
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
                            onPressed: () => onMarkFeedback("correct"),
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                            tooltip: "Right",
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                          IconButton(
                            onPressed: () => onMarkFeedback("incorrect"),
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
            
            if (isStudent && (!hasSolution || homework.tutorFeedback?.toLowerCase() == 'incorrect') && !isFailed) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onUploadSolution,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Upload Solution'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: onCouldNotDoIt,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('Couldn\'t do it'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (isStudent) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(Icons.archive, size: 16, color: secondaryTextColor),
                  label: Text('Archive', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                  onPressed: onArchive,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
