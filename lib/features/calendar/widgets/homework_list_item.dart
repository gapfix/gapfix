import 'package:flutter/material.dart';
import 'package:gapfix/models/homework_message_model.dart';
import 'package:gapfix/core/file_opener.dart';

import 'package:gapfix/core/theme.dart';

class HomeworkListItem extends StatelessWidget {
  final HomeworkMessageModel homework;
  final VoidCallback onUploadSolution;
  final VoidCallback onCouldNotDoIt;
  final VoidCallback onArchive;
  final bool isStudent;

  const HomeworkListItem({
    super.key,
    required this.homework,
    required this.onUploadSolution,
    required this.onCouldNotDoIt,
    required this.onArchive,
    required this.isStudent,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = homework.homeworkStatus == 'done';
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
                if (isDone)
                  const Icon(Icons.check_circle, color: Colors.green)
                else if (isFailed)
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
            if (isDone && homework.solutionUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: OutlinedButton.icon(
                  onPressed: () => FileOpener.openFile(context, homework.solutionUrl!, title: 'Homework Solution'),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('View Solution', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
            if (isStudent && !isDone && !isFailed) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onUploadSolution,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
            ]
          ],
        ),
      ),
    );
  }
}
