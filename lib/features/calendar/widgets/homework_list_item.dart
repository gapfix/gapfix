import 'package:flutter/material.dart';
import 'package:gapfix/models/homework_message_model.dart';
import 'package:url_launcher/url_launcher.dart';

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (isDone)
                  const Icon(Icons.check_circle, color: Colors.green)
                else if (isFailed)
                  const Icon(Icons.error, color: Colors.red)
              ],
            ),
            const SizedBox(height: 8),
            Text(homework.text ?? 'No description provided.'),
            const SizedBox(height: 12),
            if (homework.fileUrl != null)
              OutlinedButton.icon(
                onPressed: () => _openUrl(homework.fileUrl!),
                icon: const Icon(Icons.attachment),
                label: const Text('View Homework File'),
              ),
            if (isDone && homework.solutionUrl != null)
              OutlinedButton.icon(
                onPressed: () => _openUrl(homework.solutionUrl!),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('View Solution'),
              ),
            if (isStudent && !isDone && !isFailed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onUploadSolution,
                      child: const Text('Upload Solution'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: onCouldNotDoIt,
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Couldn\'t do it'),
                    ),
                  ),
                ],
              ),
            ],
            if (isStudent) ...[
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.archive),
                  tooltip: 'Archive Homework',
                  onPressed: onArchive,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
