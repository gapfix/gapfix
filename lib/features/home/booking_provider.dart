import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../models/booking_model.dart';

final bookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  final profile = ref.watch(userProfileProvider).value;
  if (profile == null) return Stream.value([]);

  final role = profile.role; // Student or Tutor
  final dbRef = FirebaseDatabase.instance.ref('Bookings');
  
  // In the real app, we might want to filter by userId in the query if possible,
  // but for RTDB with this structure, we might need to fetch and filter in Flutter 
  // unless we have specific indices or separate nodes for Student/Tutor bookings.
  // Based on your structure, let's assume we filter in code for now or 
  // check if there's a better node.
  
  return dbRef.onValue.map((event) {
    if (!event.snapshot.exists) return [];
    
    final Map<dynamic, dynamic> bookingsMap = event.snapshot.value as Map<dynamic, dynamic>;
    final List<BookingModel> bookings = [];
    
    bookingsMap.forEach((key, value) {
      final booking = BookingModel.fromMap(key.toString(), value as Map);
      if (role == 'Student' && booking.studentId == user.uid) {
        bookings.add(booking);
      } else if (role == 'Tutor' && booking.tutorId == user.uid) {
        bookings.add(booking);
      }
    });
    
    return bookings;
  });
});
