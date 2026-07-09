import 'package:flutter/material.dart';
import 'package:gapfix/models/booking_model.dart';
import 'package:intl/intl.dart';

class BookingListItem extends StatefulWidget {
  final BookingModel booking;
  final bool isStudent;
  final List<BookingModel> allBookings;
  final Function(BookingModel) onCancel;
  final Function(BookingModel) onReschedule;
  final Function(BookingModel) onJoin;
  final Function(BookingModel) onAccept;
  final Function(BookingModel) onReject;
  final Function(BookingModel) onWithdrawProposal;
  final bool showLessonNumber;

  const BookingListItem({
    super.key,
    required this.booking,
    required this.isStudent,
    required this.allBookings,
    required this.onCancel,
    required this.onReschedule,
    required this.onJoin,
    required this.onAccept,
    required this.onReject,
    required this.onWithdrawProposal,
    this.showLessonNumber = true,
  });

  @override
  State<BookingListItem> createState() => _BookingListItemState();
}

class _BookingListItemState extends State<BookingListItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isStudent = widget.isStudent;
    final allBookings = widget.allBookings;

    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('E, MMM d');
    final dt = DateTime.fromMillisecondsSinceEpoch(booking.timestamp);
    
    final otherName = isStudent 
        ? (booking.tutorName?.isNotEmpty == true ? booking.tutorName! : 'Tutor') 
        : (booking.studentName?.isNotEmpty == true ? booking.studentName! : 'Student');

    List<BookingModel> packageBookings = [];
    String subjectText = booking.subject.isNotEmpty ? booking.subject : 'Class Session';
    final splitIndex = subjectText.indexOf(' • Lesson');
    if (splitIndex != -1) {
      subjectText = subjectText.substring(0, splitIndex).trim();
    }

    if (booking.isPackage) {
      int lessonIndex = 1;
      if (booking.packageId != null) {
        packageBookings = allBookings
            .where((b) => b.packageId == booking.packageId)
            .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final index = packageBookings.indexWhere((b) => b.id == booking.id);
        if (index != -1) {
          lessonIndex = index + 1;
        }
      }
      if (widget.showLessonNumber) {
        subjectText += ' • Lesson $lessonIndex';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF333333), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Profile Image, Name, Date
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF444444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white54, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    otherName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(dt),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Subject, Time
            Padding(
              padding: const EdgeInsets.only(left: 52.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      subjectText,
                      style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(dt),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Row 3: Status
            Padding(
              padding: const EdgeInsets.only(left: 52.0),
              child: Text(
                '[${booking.status.toUpperCase()}]',
                style: TextStyle(
                  color: _getStatusColor(booking.status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Row 4: Package Badge and Duration
            Padding(
              padding: const EdgeInsets.only(left: 52.0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (booking.isPackage)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF00C853)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Package: ${booking.packageTotalLessons} Lessons',
                        style: const TextStyle(color: Color(0xFF00C853), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(
                    'Duration: ${booking.duration} mins',
                    style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pattern Change Details
            if (booking.isPackage && booking.suggestedSourceDay != null && booking.suggestedDestDay != null && booking.suggestedSourceDay != 'This Lesson' && booking.status.toLowerCase() == 'suggestion_pending')
               _buildPatternChangeDetails(booking),

            // Suggestion details
            if (booking.status.toLowerCase() == 'suggestion_pending' && (booking.suggestedTimestamp != null || (booking.suggestionMessage?.isNotEmpty ?? false)))
              _buildSuggestionDetails(booking),

            // Review Calendar Link
            if (booking.isPackage)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Review Calendar',
                    style: const TextStyle(color: Color(0xFF00C853), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // View all lessons in package
            if (booking.isPackage)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(left: 52.0, bottom: 16.0),
                  child: Text(
                    _isExpanded ? '▲ Hide all lessons in package' : '▼ View all lessons in package',
                    style: const TextStyle(color: Color(0xFF00C853), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
            if (booking.isPackage && _isExpanded)
              _buildPackageLessonsList(packageBookings, booking.id),

            // Actions Row
            if (_shouldShowActions()) _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternChangeDetails(BookingModel booking) {
    return Padding(
      padding: const EdgeInsets.only(left: 52.0, bottom: 16.0, right: 0.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Proposed Pattern Change', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              'Move from ${booking.suggestedSourceDay} to ${booking.suggestedDestDay} at ${booking.suggestedTime}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionDetails(BookingModel booking) {
    return Padding(
      padding: const EdgeInsets.only(left: 52.0, bottom: 16.0, right: 0.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Proposed Time Change', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            if (booking.suggestedTimestamp != null)
              Text(
                'New Time: ${DateFormat('MMM dd, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(booking.suggestedTimestamp!))}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            if (booking.suggestionMessage != null && booking.suggestionMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Message: "${booking.suggestionMessage}"',
                style: const TextStyle(color: Color(0xFFCCCCCC), fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackageLessonsList(List<BookingModel> packageBookings, String currentId) {
    return Padding(
      padding: const EdgeInsets.only(left: 52.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(packageBookings.length, (index) {
          final b = packageBookings[index];
          final bDt = DateTime.fromMillisecondsSinceEpoch(b.timestamp);
          final bFormat = DateFormat('MMM d, HH:mm (E)');
          final isCurrent = b.id == currentId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0, right: 0.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'L${index + 1}: ${bFormat.format(bDt)}',
                    style: TextStyle(
                      color: isCurrent ? const Color(0xFF00C853) : const Color(0xFFCCCCCC),
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '[${b.status.toUpperCase()}]',
                  style: TextStyle(color: _getStatusColor(b.status), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  bool _shouldShowActions() {
    final status = widget.booking.status.toLowerCase();
    return status != 'cancelled' && status != 'finished' && status != 'completed';
  }

  Widget _buildActions(BuildContext context) {
    final booking = widget.booking;
    final isStudent = widget.isStudent;
    final status = booking.status.toLowerCase();
    
    if (status == 'confirmed') {
      return Column(
        children: [
          ElevatedButton(
            onPressed: () => widget.onJoin(booking),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Join', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onReschedule(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF444444),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reschedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onCancel(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (status == 'suggestion_pending') {
      final myRole = isStudent ? 'student' : 'tutor';
      if (booking.lastSuggestedBy != myRole) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onAccept(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Accept', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onReject(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF444444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Reject', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      } else {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onReschedule(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF444444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Edit Request', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onWithdrawProposal(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Withdraw', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      }
    } else if (status == 'pending' || status == 'free_trial_pending') {
      if (isStudent) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onReschedule(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF444444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Edit Request', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onCancel(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      } else {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onAccept(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Accept', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onReject(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF444444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Reject', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      }
    }
    return const SizedBox.shrink();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return const Color(0xFF00C853);
      case 'pending':
      case 'suggestion_pending':
      case 'free_trial_pending':
        return Colors.orange;
      case 'cancelled':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.blue;
    }
  }
}
