import 'package:gapfix/models/booking_model.dart';

class LessonTimeHelper {
  static const int tutorJoinWindowMinutes = 5;
  static const int defaultDurationMinutes = 60;

  static bool isJoinable(BookingModel booking, bool isStudent) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final start = booking.timestamp;
    final windowStart = isStudent 
        ? start 
        : start - (tutorJoinWindowMinutes * 60 * 1000);
    
    final duration = booking.duration > 0 ? booking.duration : defaultDurationMinutes;
    final windowEnd = start + (duration * 60 * 1000);
    
    return now >= windowStart && now <= windowEnd;
  }

  static int minutesUntilJoinable(BookingModel booking, bool isStudent) {
    final start = booking.timestamp;
    final windowStart = isStudent 
        ? start 
        : start - (tutorJoinWindowMinutes * 60 * 1000);
    
    final diff = windowStart - DateTime.now().millisecondsSinceEpoch;
    return diff <= 0 ? 0 : (diff ~/ (60 * 1000));
  }
}
