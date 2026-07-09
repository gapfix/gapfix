import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:gapfix/models/booking_model.dart';
import 'package:gapfix/models/homework_message_model.dart';
import 'package:gapfix/features/calendar/widgets/calendar_grid.dart';
import 'package:gapfix/features/calendar/widgets/booking_list_item.dart';
import 'package:gapfix/features/calendar/widgets/homework_list_item.dart';
import 'package:gapfix/features/calendar/widgets/reschedule_sheet.dart';
import 'package:gapfix/core/lesson_time_helper.dart';
import 'package:gapfix/core/toast_utils.dart';
import 'package:intl/intl.dart';
import 'package:gapfix/core/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

class CalendarScreen extends StatefulWidget {
  final bool isStudent;

  const CalendarScreen({super.key, required this.isStudent});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'gapfix');

  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  final Set<String> _bookingDates = {};
  final Set<String> _homeworkDates = {};
  final Set<String> _combinedDates = {};

  final List<BookingModel> _allBookings = [];
  List<BookingModel> _bookingsForDate = [];
  List<HomeworkMessageModel> _homeworkForDate = [];
  final Map<String, List<HomeworkMessageModel>> _homeworkByChat = {};

  StreamSubscription? _bookingsSub;
  StreamSubscription? _chatsSub;
  final List<StreamSubscription> _messagesSubs = [];

  bool _isLoading = true;

  int _pendingBadgeCount = 0;

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
      _allBookings.clear();
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final booking = BookingModel.fromMap(key.toString(), value as Map<dynamic, dynamic>);
          // Debug: verify package parsing
          if (booking.packageId != null || (value)['package'] == true || (value)['isPackage'] == true) {
            debugPrint('📦 BOOKING ${booking.id}: isPackage=${booking.isPackage}, packageId=${booking.packageId}, raw_package=${(value)['package']}, raw_isPackage=${(value)['isPackage']}');
          }
          _allBookings.add(booking);
          if (booking.status.toLowerCase() != 'cancelled') {
            final date = DateTime.fromMillisecondsSinceEpoch(booking.timestamp);
            _bookingDates.add('${date.year}-${date.month}-${date.day}');
            
            if (booking.status.toLowerCase() == 'suggestion_pending' && booking.suggestedTimestamp != null) {
              final sDate = DateTime.fromMillisecondsSinceEpoch(booking.suggestedTimestamp!);
              _bookingDates.add('${sDate.year}-${sDate.month}-${sDate.day}');
            }
          }
        });
      }
      _refreshCombinedDates();
      _loadDataForSelectedDate();
      _updateBadgeCount();
    });

    // Fetch Homework (Chats -> Messages)
    _chatsSub = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'gapfix')
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

  void _updateBadgeCount() {
    int count = 0;
    final Set<String> countedPackages = {};
    
    for (var b in _allBookings) {
      if (b.status.toLowerCase() == 'suggestion_pending') {
        if (b.isPackage && b.packageId != null) {
          if (!countedPackages.contains(b.packageId)) {
            countedPackages.add(b.packageId!);
            count++;
          }
        } else {
          count++;
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _pendingBadgeCount = count;
      });
    }
  }

  void _refreshCombinedDates() {
    _combinedDates.clear();
    _combinedDates.addAll(_bookingDates);
    _combinedDates.addAll(_homeworkDates);
    if (mounted) setState(() {});
  }

  void _loadDataForSelectedDate() {
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59, 999).millisecondsSinceEpoch;
    final dateKey = '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';

    final List<BookingModel> filtered = [];
    final Set<String> seenPackageIds = {};

    // Sort all bookings by timestamp to ensure we pick the earliest one for packages
    final sortedAll = List<BookingModel>.from(_allBookings)..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var b in sortedAll) {
      bool isOnSelectedDate = (b.timestamp >= startOfDay && b.timestamp <= endOfDay);
      if (b.status.toLowerCase() == 'suggestion_pending' && b.suggestedTimestamp != null) {
        if (b.suggestedTimestamp! >= startOfDay && b.suggestedTimestamp! <= endOfDay) {
          isOnSelectedDate = true;
        }
      }

      if (isOnSelectedDate) {
        if (b.isPackage && b.packageId != null) {
          if (!seenPackageIds.contains(b.packageId)) {
            seenPackageIds.add(b.packageId!);
            filtered.add(b);
          }
        } else {
          filtered.add(b);
        }
      }
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
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
  }

  Future<void> _handleUploadSolution(HomeworkMessageModel homework) async {
    if (homework.chatId == null) return;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg'],
        withData: true,
      );
      
      if (result == null) {
        print('FilePicker returned null');
        return;
      }
      
      print('File picked: ${result.files.single.name}');
      print('Has bytes: ${result.files.single.bytes != null}');
      print('Has path: ${result.files.single.path != null}');

      if (result.files.single.path != null || result.files.single.bytes != null) {
        if (!mounted) return;
        ToastUtils.show(context, 'Uploading solution...');

        final cloudinary = CloudinaryPublic('dbugqpl3m', 'ml_default', cache: false);
        
        CloudinaryResponse response;
        if (kIsWeb || result.files.single.path == null) {
          response = await cloudinary.uploadFile(
            CloudinaryFile.fromBytesData(
              result.files.single.bytes!.toList(),
              identifier: result.files.single.name,
              folder: 'Solutions/${homework.chatId}',
            ),
          );
        } else {
          response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              result.files.single.path!,
              folder: 'Solutions/${homework.chatId}',
            ),
          );
        }

        await _firestore
            .collection('chats')
            .doc(homework.chatId)
            .collection('messages')
            .doc(homework.documentId)
            .update({
          'solutionUrl': response.secureUrl,
          'homeworkStatus': 'awaiting_review',
          'tutorFeedback': FieldValue.delete(),
        });

        if (mounted) {
          ToastUtils.show(context, 'Solution uploaded successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Upload failed: $e', isError: true);
      }
    }
  }

  Future<void> _handleCouldNotDoIt(HomeworkMessageModel homework) async {
    if (homework.chatId == null) return;
    try {
      await _firestore
          .collection('chats')
          .doc(homework.chatId)
          .collection('messages')
          .doc(homework.documentId)
          .update({'homeworkStatus': 'failed'});
      if (mounted) {
        ToastUtils.show(context, 'Status updated');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _handleMarkFeedback(HomeworkMessageModel homework, String feedback) async {
    if (homework.chatId == null) return;
    try {
      await _firestore
          .collection('chats')
          .doc(homework.chatId)
          .collection('messages')
          .doc(homework.documentId)
          .update({'tutorFeedback': feedback});
      
      if (mounted) {
        ToastUtils.show(context, 'Marked as $feedback');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Error updating feedback: $e', isError: true);
      }
    }
  }

  Future<void> _handleArchiveHomework(HomeworkMessageModel homework) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || homework.fileUrl == null) return;

    try {
      final subject = (homework.subject != null && homework.subject!.isNotEmpty) ? homework.subject! : 'General';
      final title = (homework.text != null && homework.text!.isNotEmpty) ? homework.text! : 'Archived Homework';
      
      final safeTitle = title.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
      final safeSubject = subject.replaceAll(RegExp(r'[.#$\[\]/]'), '_');

      final ref = FirebaseDatabase.instance
          .ref('Users')
          .child('Student')
          .child(user.uid)
          .child('Archives')
          .child(safeSubject)
          .child(safeTitle);

      await ref.set({
        'documentId': homework.documentId,
        'studentId': user.uid,
        'subject': safeSubject,
        'fileUrl': homework.fileUrl,
        'title': safeTitle,
        'timestamp': ServerValue.timestamp,
      });

      if (mounted) {
        ToastUtils.show(context, 'Added to Archive');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Failed to archive: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final monthFormat = DateFormat('MMMM yyyy');
    final titleColor = isDark ? theme.colorScheme.onSurface : AppTheme.textDark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 900;
            
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Calendar
                  SizedBox(
                    width: 450,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeader(titleColor, theme),
                          _buildCalendarCard(theme, monthFormat),
                        ],
                      ),
                    ),
                  ),
                  // Vertical Divider
                  Container(width: 1, color: isDark ? Colors.white10 : Colors.grey[200]),
                  // Right side: Schedule
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScheduleSection(isDark),
                          _buildHomeworkSection(isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Normal Mobile/Narrow Layout
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(titleColor, theme),
                  _buildCalendarCard(theme, monthFormat),
                  const SizedBox(height: 24),
                  _buildScheduleSection(isDark),
                  _buildHomeworkSection(isDark),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Color titleColor, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Upcoming Classes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.assignment_outlined, color: theme.primaryColor, size: 28),
                onPressed: () {
                  context.push('/sessions', extra: widget.isStudent);
                },
              ),
              if (_pendingBadgeCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$_pendingBadgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(ThemeData theme, DateFormat monthFormat) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: theme.cardTheme.shape is RoundedRectangleBorder
              ? Border.fromBorderSide((theme.cardTheme.shape as RoundedRectangleBorder).side)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      monthFormat.format(_currentMonth),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppTheme.primary),
                    onPressed: () => _changeMonth(-1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppTheme.primary),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CalendarGrid(
                currentMonth: _currentMonth,
                selectedDate: _selectedDate,
                activeDates: _combinedDates,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                  _loadDataForSelectedDate();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Schedule',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_bookingsForDate.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                const Text(
                  'No upcoming classes',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: _bookingsForDate.length,
            itemBuilder: (context, index) {
              return BookingListItem(
                booking: _bookingsForDate[index],
                isStudent: widget.isStudent,
                allBookings: _allBookings,
                onCancel: (booking) async {
                  final now = DateTime.now().millisecondsSinceEpoch;
                  if (booking.isPackage && booking.packageId != null) {
                    final updates = <String, dynamic>{};
                    for (var b in _allBookings.where((b) => b.packageId == booking.packageId)) {
                      if (b.timestamp > now && !['finished', 'done', 'completed', 'cancelled'].contains(b.status.toLowerCase())) {
                        updates['${b.id}/status'] = 'cancelled';
                        updates['${b.id}/cancellationReason'] = 'Cancelled from app';
                      }
                    }
                    if (updates.isNotEmpty) {
                      await FirebaseDatabase.instance.ref('Bookings').update(updates);
                    }
                  } else {
                    await FirebaseDatabase.instance.ref('Bookings').child(booking.id).update({
                      'status': 'cancelled',
                      'cancellationReason': 'Cancelled from app',
                    });
                  }
                  if (context.mounted) {
                    ToastUtils.show(context, 'Booking Cancelled');
                  }
                },
                onReschedule: (booking) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => RescheduleSheet(
                      booking: booking,
                      allBookings: _allBookings,
                      isStudent: widget.isStudent,
                    ),
                  );
                },
                onJoin: (booking) {
                  if (LessonTimeHelper.isJoinable(booking, widget.isStudent)) {
                    context.push('/video-call', extra: {
                      'booking': booking,
                      'isStudent': widget.isStudent,
                    });
                  } else {
                    final minutes = LessonTimeHelper.minutesUntilJoinable(booking, widget.isStudent);
                    if (minutes > 0) {
                      ToastUtils.show(context, 'Class will be joinable in $minutes minutes');
                    } else {
                      ToastUtils.show(context, 'This class has already ended.', isError: true);
                    }
                  }
                },
                onAccept: _handleAccept,
                onReject: _handleReject,
                onWithdrawProposal: _handleWithdrawProposal,
              );
            },
          ),
      ],
    );
  }

  Future<void> _handleAccept(BookingModel booking) async {
    try {
      final ref = FirebaseDatabase.instance.ref('Bookings');
      final updates = <String, dynamic>{
        'status': 'confirmed',
        'suggestedTimestamp': null,
        'suggestedSourceDay': null,
        'suggestedDestDay': null,
        'suggestedTime': null,
        'suggestionMessage': null,
      };

      bool isSingleLessonMove = booking.suggestedTimestamp != null && booking.suggestedTimestamp! > 0;
      bool isPatternMove = (booking.isPackage &&
          booking.packageId != null &&
          booking.suggestedSourceDay != null &&
          booking.suggestedDestDay != null &&
          booking.suggestedTime != null &&
          booking.suggestedSourceDay != 'This Lesson');

      if (isPatternMove) {
        final String sourceDay = booking.suggestedSourceDay!.replaceFirst('s', ''); 
        final String destDay = booking.suggestedDestDay!.replaceFirst('s', '');
        final List<String> times = booking.suggestedTime!.split(':');
        final int hour = int.parse(times[0]);
        final int minute = int.parse(times[1]);

        final packageLessons = _allBookings.where((b) => b.packageId == booking.packageId).toList();
        final now = DateTime.now().millisecondsSinceEpoch;
        final Map<String, dynamic> multiUpdates = {};

        for (var lesson in packageLessons) {
          final dt = DateTime.fromMillisecondsSinceEpoch(lesson.timestamp);
          final dayName = DateFormat('EEEE').format(dt);

          if (dayName == sourceDay && lesson.timestamp > now) {
            int daysToAdd = _getDayDifference(sourceDay, destDay);
            DateTime newDate = dt.add(Duration(days: daysToAdd));
            DateTime finalDate = DateTime(newDate.year, newDate.month, newDate.day, hour, minute);

            multiUpdates['${lesson.id}/timestamp'] = finalDate.millisecondsSinceEpoch;
            multiUpdates['${lesson.id}/status'] = 'confirmed';
          }
        }
        updates.forEach((key, value) {
          multiUpdates['${booking.id}/$key'] = value;
        });
        await ref.update(multiUpdates);
      } else if (isSingleLessonMove) {
        updates['timestamp'] = booking.suggestedTimestamp;
        await ref.child(booking.id).update(updates);
      } else if (booking.isPackage && booking.packageId != null) {
        final packageLessons = _allBookings.where((b) => b.packageId == booking.packageId).toList();
        final Map<String, dynamic> multiUpdates = {};
        for (var lesson in packageLessons) {
          updates.forEach((k, v) => multiUpdates['${lesson.id}/$k'] = v);
        }
        if (multiUpdates.isNotEmpty) {
          await ref.update(multiUpdates);
        }
      } else {
        await ref.child(booking.id).update(updates);
      }
      
      if (mounted) {
        ToastUtils.show(context, 'Booking Confirmed!');
      }
    } catch (e) {
      debugPrint('Accept error: $e');
      if (mounted) {
        ToastUtils.show(context, 'Error accepting change: $e', isError: true);
      }
    }
  }

  int _getDayDifference(String source, String dest) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    int sIdx = days.indexOf(source);
    int dIdx = days.indexOf(dest);
    if (sIdx == -1 || dIdx == -1) return 0;
    int diff = dIdx - sIdx;
    return diff;
  }

  Future<void> _handleReject(BookingModel booking) async {
    try {
      await FirebaseDatabase.instance.ref('Bookings').child(booking.id).update({
        'status': 'confirmed',
        'suggestedTimestamp': null,
        'suggestedSourceDay': null,
        'suggestedDestDay': null,
        'suggestedTime': null,
        'suggestionMessage': null,
      });
      if (mounted) {
        ToastUtils.show(context, 'Proposal Rejected');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Error rejecting: $e', isError: true);
      }
    }
  }

  Future<void> _handleWithdrawProposal(BookingModel booking) async {
    try {
      await FirebaseDatabase.instance.ref('Bookings').child(booking.id).update({
        'status': 'confirmed',
        'suggestedTimestamp': null,
        'suggestedSourceDay': null,
        'suggestedDestDay': null,
        'suggestedTime': null,
        'suggestionMessage': null,
        'lastSuggestedBy': null,
      });
      if (mounted) {
        ToastUtils.show(context, 'Proposal Withdrawn');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Error withdrawing: $e', isError: true);
      }
    }
  }

  Widget _buildHomeworkSection(bool isDark) {
    if (_homeworkForDate.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Homeworks',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          itemCount: _homeworkForDate.length,
          itemBuilder: (context, index) {
            return HomeworkListItem(
              homework: _homeworkForDate[index],
              isStudent: widget.isStudent,
              onUploadSolution: () => _handleUploadSolution(_homeworkForDate[index]),
              onCouldNotDoIt: () => _handleCouldNotDoIt(_homeworkForDate[index]),
              onArchive: () => _handleArchiveHomework(_homeworkForDate[index]),
              onMarkFeedback: (feedback) => _handleMarkFeedback(_homeworkForDate[index], feedback),
            );
          },
        ),
      ],
    );
  }
}
