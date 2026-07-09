import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gapfix/models/booking_model.dart';
import 'package:gapfix/features/calendar/widgets/booking_list_item.dart';
import 'package:gapfix/features/calendar/widgets/reschedule_sheet.dart';
import 'package:gapfix/core/lesson_time_helper.dart';
import 'package:gapfix/core/toast_utils.dart';
import 'package:intl/intl.dart';
import 'package:gapfix/core/theme.dart';
import 'package:go_router/go_router.dart';

class SessionsScreen extends StatefulWidget {
  final bool isStudent;

  const SessionsScreen({super.key, required this.isStudent});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> with SingleTickerProviderStateMixin {
  final List<BookingModel> _fullList = [];
  final List<BookingModel> _filteredList = [];
  bool _isLoading = true;
  StreamSubscription? _bookingsSub;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _filterData(_tabController.index);
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final queryField = widget.isStudent ? 'studentId' : 'tutorId';
    _bookingsSub = FirebaseDatabase.instance
        .ref('Bookings')
        .orderByChild(queryField)
        .equalTo(user.uid)
        .onValue
        .listen((event) {
      if (!mounted) return;

      final List<BookingModel> loadedBookings = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          loadedBookings.add(BookingModel.fromMap(key.toString(), value as Map<dynamic, dynamic>));
        });
      }

      _fullList.clear();
      _fullList.addAll(loadedBookings);

      _updateBadgesAndFilter();
      _checkExpiredBookings(loadedBookings);
    });
  }

  void _updateBadgesAndFilter() {
    setState(() {
      _isLoading = false;
      _filterData(_tabController.index);
    });
  }

  void _checkExpiredBookings(List<BookingModel> bookings) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final Map<String, dynamic> updates = {};
    
    for (var b in bookings) {
      final endTime = b.timestamp + (b.duration * 60 * 1000);
      final status = b.status.toLowerCase();
      if (now > endTime && (['confirmed', 'pending', 'free_trial_pending', 'suggestion_pending'].contains(status))) {
        updates['${b.id}/status'] = 'cancelled';
        updates['${b.id}/cancellationReason'] = 'Time expired';
      }
    }

    if (updates.isNotEmpty) {
      FirebaseDatabase.instance.ref('Bookings').update(updates);
    }
  }

  void _filterData(int tabIndex) {
    _filteredList.clear();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final Set<String> pendingPackageIds = {};
    final Set<String> confirmedFuturePackageIds = {};
    
    for (var b in _fullList) {
      if (b.isPackage && b.packageId != null) {
        final s = b.status.toLowerCase();
        final endTime = b.timestamp + (b.duration * 60 * 1000);
        if (s.contains('pending') || s.contains('suggestion')) {
          pendingPackageIds.add(b.packageId!);
        } else if (s == 'confirmed' && now < endTime) {
          confirmedFuturePackageIds.add(b.packageId!);
        }
      }
    }

    final Set<String> addedPackages = {};
    for (var b in _fullList) {
      final status = b.status.toLowerCase();
      final pkgId = b.packageId;
      final isPkg = b.isPackage && pkgId != null;
      final endTime = b.timestamp + (b.duration * 60 * 1000);
      bool match = false;

      if (tabIndex == 0) { // Current
        if (isPkg) {
          if (!pendingPackageIds.contains(pkgId) && status == 'confirmed' && now < endTime) {
            match = true;
          }
        } else if (status == 'confirmed' && now < endTime) {
          match = true;
        }
      } else if (tabIndex == 1) { // Pending
        if (isPkg) {
          if (pendingPackageIds.contains(pkgId) && (status.contains('pending') || status.contains('suggestion'))) {
            match = true;
          }
        } else {
          if (status.contains('pending') || status.contains('suggestion')) match = true;
        }
      } else if (tabIndex == 2) { // History
        if (isPkg) {
          bool isActive = pendingPackageIds.contains(pkgId) || confirmedFuturePackageIds.contains(pkgId);
          if (!isActive && ['finished', 'done', 'cancelled', 'completed'].contains(status)) {
            match = true;
          }
        } else {
          if (['finished', 'done', 'cancelled', 'completed'].contains(status)) match = true;
        }
      }

      if (match) {
        if (isPkg) {
          if (!addedPackages.contains(pkgId)) {
            BookingModel representative = b;
            if (status != 'suggestion_pending') {
              for (var other in _fullList) {
                if (other.packageId == pkgId && other.status.toLowerCase() == 'suggestion_pending') {
                  representative = other;
                  break;
                }
              }
            }
            _filteredList.add(representative);
            addedPackages.add(pkgId);
          }
        } else {
          _filteredList.add(b);
        }
      }
    }
    
    setState(() {
      _filteredList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  Future<void> _handleCancel(BookingModel booking) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (booking.isPackage && booking.packageId != null) {
      final updates = <String, dynamic>{};
      for (var b in _fullList.where((b) => b.packageId == booking.packageId)) {
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
    if (mounted) {
      ToastUtils.show(context, 'Booking Cancelled');
    }
  }

  void _handleReschedule(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RescheduleSheet(
        booking: booking,
        allBookings: _fullList,
        isStudent: widget.isStudent,
      ),
    );
  }

  void _handleJoin(BookingModel booking) {
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
  }

  Future<void> _handleAccept(BookingModel booking) async {
    try {
      final ref = FirebaseDatabase.instance.ref('Bookings');
      final Map<String, dynamic> multiUpdates = {};

      final updates = <String, dynamic>{
        'status': 'confirmed',
        'suggestedTimestamp': null,
        'suggestedSourceDay': null,
        'suggestedDestDay': null,
        'suggestedTime': null,
        'suggestionMessage': null,
        'lastSuggestedBy': null,
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

        final packageLessons = _fullList.where((b) => b.packageId == booking.packageId).toList();
        final now = DateTime.now().millisecondsSinceEpoch;

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
      } else if (isSingleLessonMove) {
        updates['timestamp'] = booking.suggestedTimestamp;
        updates.forEach((key, value) {
          multiUpdates['${booking.id}/$key'] = value;
        });
      } else if (booking.isPackage && booking.packageId != null) {
        final packageLessons = _fullList.where((b) => b.packageId == booking.packageId).toList();
        for (var lesson in packageLessons) {
          updates.forEach((k, v) => multiUpdates['${lesson.id}/$k'] = v);
        }
      } else {
        updates.forEach((key, value) {
          multiUpdates['${booking.id}/$key'] = value;
        });
      }

      await ref.update(multiUpdates);
      
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
        'lastSuggestedBy': null,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sessions'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Pending'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(),
                _buildList(),
                _buildList(),
              ],
            ),
    );
  }

  Widget _buildList() {
    if (_filteredList.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) {
        return BookingListItem(
          booking: _filteredList[index],
          isStudent: widget.isStudent,
          allBookings: _fullList,
          onCancel: _handleCancel,
          onReschedule: _handleReschedule,
          onJoin: _handleJoin,
          onAccept: _handleAccept,
          onReject: _handleReject,
          onWithdrawProposal: _handleWithdrawProposal,
          showLessonNumber: false,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'No sessions found',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
