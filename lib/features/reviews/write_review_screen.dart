import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/toast_utils.dart';

/// Port of Android ReviewWritingActivity.
/// Writes to Reviews/<tutorId>/<pushId> with the same fields as Android:
/// rating, review, studentId, bookingId, timestamp (ms since epoch).
class WriteReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String tutorId;
  const WriteReviewScreen({
    super.key,
    required this.bookingId,
    required this.tutorId,
  });

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _reviewController = TextEditingController();
  double _rating = 0;
  String _tutorName = '';
  String _subject = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadLessonDetails();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadLessonDetails() async {
    final db = ref.read(databaseProvider);
    try {
      final name = await db.ref('Users/Tutor/${widget.tutorId}/name').get();
      final subject = await db.ref('Bookings/${widget.bookingId}/subject').get();
      if (!mounted) return;
      setState(() {
        if (name.exists) _tutorName = name.value.toString();
        if (subject.exists) _subject = subject.value.toString();
      });
    } catch (_) {
      // Android ignores read failures here; the header just stays empty.
    }
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ToastUtils.show(context, 'Please select a rating', isError: true);
      return;
    }
    final studentId = ref.read(firebaseAuthProvider).currentUser?.uid;
    setState(() => _submitting = true);
    try {
      final reviewRef =
          ref.read(databaseProvider).ref('Reviews/${widget.tutorId}').push();
      await reviewRef.set({
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'studentId': studentId,
        'bookingId': widget.bookingId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      if (!mounted) return;
      ToastUtils.show(context, 'Review submitted! Thank you.');
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ToastUtils.show(context, 'Failed to submit review', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate your lesson')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _tutorName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _subject,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 24),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (v) => _rating = v,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Write a review (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            if (_submitting)
              const CircularProgressIndicator()
            else ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _submit,
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    side: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  child: const Text('SUBMIT',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Skip'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
