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
    
    // Fallback names if not present (although model might not have them, we use placeholder)
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
      color: const Color(0xFF1E1E1E), // Dark surface color matching Android
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF444444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white54,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      otherName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  dateFormat.format(dt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Indented Subject, Time
            Padding(
              padding: const EdgeInsets.only(left: 52.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subjectText,
                      style: const TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    timeFormat.format(dt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Row 3: Indented Status
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
              child: Row(
                children: [
                  if (booking.isPackage) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF00C853)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Package: ${booking.packageTotalLessons} Lessons',
                        style: const TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'Duration: ${booking.duration} mins',
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Review Calendar Link
            if (booking.isPackage)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Review Calendar',
                    style: const TextStyle(
                      color: Color(0xFF00C853),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // View all lessons in package
            if (booking.isPackage)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 52.0, bottom: 16.0),
                  child: Text(
                    _isExpanded ? '▲ Hide all lessons in package' : '▼ View all lessons in package',
                    style: const TextStyle(
                      color: Color(0xFF00C853),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
            if (booking.isPackage && _isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 52.0, bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(packageBookings.length, (index) {
                    final b = packageBookings[index];
                    final bDt = DateTime.fromMillisecondsSinceEpoch(b.timestamp);
                    final bFormat = DateFormat('MMM d, HH:mm (EEEE)');
                    final isCurrent = b.id == booking.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, right: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Lesson ${index + 1}: ${bFormat.format(bDt)}',
                              style: TextStyle(
                                color: isCurrent ? const Color(0xFF00C853) : const Color(0xFFCCCCCC),
                                fontSize: 14,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          Text(
                            '[${b.status.toUpperCase()}]',
                            style: TextStyle(
                              color: _getStatusColor(b.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

            // Suggestion details if pending
            if (booking.status.toLowerCase() == 'suggestion_pending')
              Padding(
                padding: const EdgeInsets.only(left: 52.0, bottom: 16.0, right: 16.0),
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
                      const Text(
                        'Proposed Change',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      if (booking.isPackage && booking.suggestedSourceDay != null && booking.suggestedDestDay != null && booking.suggestedSourceDay != 'This Lesson')
                        Text(
                          'Move pattern from ${booking.suggestedSourceDay} to ${booking.suggestedDestDay} at ${booking.suggestedTime}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        )
                      else if (booking.suggestedTimestamp != null)
                        Text(
                          'New Time: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(booking.suggestedTimestamp!))}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      if (booking.suggestionMessage != null && booking.suggestionMessage!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Message: "${booking.suggestionMessage}"',
                          style: const TextStyle(color: Color(0xFFCCCCCC), fontStyle: FontStyle.italic, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Actions Row
            if (_shouldShowActions()) _buildActions(context),
          ],
        ),
      ),
    );
  }

  bool _shouldShowActions() {
    final status = widget.booking.status.toLowerCase();
    if (status == 'cancelled') return false;
    return true;
  }

  Widget _buildActions(BuildContext context) {
    final booking = widget.booking;
    final isStudent = widget.isStudent;
    final onJoin = widget.onJoin;
    final onReschedule = widget.onReschedule;
    final onAccept = widget.onAccept;
    final onReject = widget.onReject;
    final onCancel = widget.onCancel;
    
    final status = booking.status.toLowerCase();
    
    if (status == 'confirmed') {
      return Column(
        children: [
          ElevatedButton(
            onPressed: () => onJoin(booking),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853), // Success green
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Join', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onReschedule(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF444444),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Reschedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onCancel(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B), // Error red
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
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
                onPressed: () => onAccept(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Accept', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => onReject(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF444444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
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
                onPressed: () => onReschedule(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF444444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
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
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
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
                onPressed: () => onReschedule(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF444444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Edit Request', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => onCancel(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
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
                onPressed: () => onAccept(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Accept', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => onReject(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF444444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
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
        return const Color(0xFF00C853); // Success green
      case 'pending':
      case 'suggestion_pending':
      case 'free_trial_pending':
        return Colors.orange;
      case 'cancelled':
        return const Color(0xFFFF6B6B); // Error red
      default:
        return Colors.blue;
    }
  }
}
