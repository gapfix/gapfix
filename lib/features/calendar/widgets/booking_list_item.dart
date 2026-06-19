import 'package:flutter/material.dart';
import 'package:gapfix/models/booking_model.dart';
import 'package:intl/intl.dart';

class BookingListItem extends StatelessWidget {
  final BookingModel booking;
  final bool isStudent;

  const BookingListItem({
    super.key,
    required this.booking,
    required this.isStudent,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dt = DateTime.fromMillisecondsSinceEpoch(booking.timestamp);
    final endTime = dt.add(Duration(minutes: booking.duration));
    final timeString = '${timeFormat.format(dt)} - ${timeFormat.format(endTime)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          booking.subject.isNotEmpty ? booking.subject : 'Class Session',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(timeString),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(booking.status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return Colors.green;
      case 'pending':
      case 'suggestion_pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
