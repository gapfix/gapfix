import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gapfix/models/booking_model.dart';
import 'package:gapfix/models/homework_message_model.dart';
import 'package:gapfix/features/calendar/widgets/calendar_grid.dart';
import 'package:gapfix/features/calendar/widgets/booking_list_item.dart';
import 'package:gapfix/features/calendar/widgets/homework_list_item.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  final bool isStudent;

  const CalendarScreen({super.key, required this.isStudent});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  final Set<String> _bookingDates = {};
  final Set<String> _homeworkDates = {};
  final Set<String> _combinedDates = {};

  List<BookingModel> _bookingsForDate = [];
  List<HomeworkMessageModel> _homeworkForDate = [];
  final Map<String, List<HomeworkMessageModel>> _homeworkByChat = {};

  StreamSubscription? _bookingsSub;
  StreamSubscription? _chatsSub;
  final List<StreamSubscription> _messagesSubs = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _chatsSub?.cancel();
    for (var sub in _messagesSubs) {
      sub.cancel();
    }
    super.dispose();
  }

  void _fetchAllData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final queryField = widget.isStudent ? 'studentId' : 'tutorId';

    // Fetch Bookings
    _bookingsSub = FirebaseDatabase.instance
        .ref('Bookings')
        .orderByChild(queryField)
        .equalTo(user.uid)
        .onValue
        .listen((event) {
      _bookingDates.clear();
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final booking = BookingModel.fromMap(key.toString(), value as Map<dynamic, dynamic>);
          if (booking.status.toLowerCase() != 'cancelled') {
            final date = DateTime.fromMillisecondsSinceEpoch(booking.timestamp);
            _bookingDates.add('${date.year}-${date.month}-${date.day}');
          }
        });
      }
      _refreshCombinedDates();
      _loadDataForSelectedDate();
    });

    // Fetch Homework (Chats -> Messages)
    _chatsSub = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((chatsSnap) {
      for (var doc in chatsSnap.docs) {
        final chatId = doc.id;
        if (!_homeworkByChat.containsKey(chatId)) {
          final sub = doc.reference
              .collection('messages')
              .where('type', isEqualTo: 'homework')
              .snapshots()
              .listen((messagesSnap) {
            final list = messagesSnap.docs.map((mDoc) => HomeworkMessageModel.fromFirestore(mDoc, chatId)).toList();
            _homeworkByChat[chatId] = list;
            _rebuildHomeworkState();
          });
          _messagesSubs.add(sub);
        }
      }
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _rebuildHomeworkState() {
    _homeworkDates.clear();
    for (var list in _homeworkByChat.values) {
      for (var hm in list) {
        final ts = hm.lessonTimestamp > 0 ? hm.lessonTimestamp : (hm.timestamp?.millisecondsSinceEpoch ?? 0);
        if (ts > 0) {
          final date = DateTime.fromMillisecondsSinceEpoch(ts);
          _homeworkDates.add('${date.year}-${date.month}-${date.day}');
        }
      }
    }
    _refreshCombinedDates();
    _loadDataForSelectedDate();
  }

  void _refreshCombinedDates() {
    _combinedDates.clear();
    _combinedDates.addAll(_bookingDates);
    _combinedDates.addAll(_homeworkDates);
    if (mounted) setState(() {});
  }

  void _loadDataForSelectedDate() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59, 999).millisecondsSinceEpoch;
    final dateKey = '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';

    final queryField = widget.isStudent ? 'studentId' : 'tutorId';

    // Filter Bookings locally or fetch again. It's better to fetch for the specific date or just filter locally.
    // For simplicity, we filter from a one-time fetch here.
    FirebaseDatabase.instance
        .ref('Bookings')
        .orderByChild(queryField)
        .equalTo(user.uid)
        .once()
        .then((event) {
      final List<BookingModel> filtered = [];
      final Set<String> seenPackages = {};

      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final b = BookingModel.fromMap(key.toString(), value as Map<dynamic, dynamic>);
          if (b.timestamp >= startOfDay && b.timestamp <= endOfDay) {
            if (b.isPackage && b.packageId != null) {
              if (!seenPackages.contains(b.packageId)) {
                seenPackages.add(b.packageId!);
                filtered.add(b);
              }
            } else {
              filtered.add(b);
            }
          }
        });
      }

      // Filter Homework locally
      final List<HomeworkMessageModel> hmFiltered = [];
      for (var list in _homeworkByChat.values) {
        for (var hm in list) {
          final ts = hm.lessonTimestamp > 0 ? hm.lessonTimestamp : (hm.timestamp?.millisecondsSinceEpoch ?? 0);
          if (ts > 0) {
            final cal = DateTime.fromMillisecondsSinceEpoch(ts);
            if ('${cal.year}-${cal.month}-${cal.day}' == dateKey) {
              hmFiltered.add(hm);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _bookingsForDate = filtered..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _homeworkForDate = hmFiltered;
        });
      }
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final monthFormat = DateFormat('MMMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              // Navigate to sessions activity if needed
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Month/Year Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  monthFormat.format(_currentMonth),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // Calendar Grid
          CalendarGrid(
            currentMonth: _currentMonth,
            selectedDate: _selectedDate,
            activeDates: _combinedDates,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
              _loadDataForSelectedDate();
            },
          ),

          const Divider(),

          // List of items
          Expanded(
            child: _bookingsForDate.isEmpty && _homeworkForDate.isEmpty
                ? const Center(
                    child: Text(
                      'No classes or homework for this date',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView(
                    children: [
                      if (_bookingsForDate.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        ..._bookingsForDate.map((b) => BookingListItem(booking: b, isStudent: widget.isStudent)),
                      ],
                      if (_homeworkForDate.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('Homework', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        ..._homeworkForDate.map((h) => HomeworkListItem(
                              homework: h,
                              isStudent: widget.isStudent,
                              onUploadSolution: () {
                                // Implement upload logic
                              },
                              onCouldNotDoIt: () {
                                // Implement status update
                              },
                              onArchive: () {
                                // Implement archive
                              },
                            )),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
