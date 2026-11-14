import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../features/home/booking_provider.dart';
import '../models/booking_model.dart';
import 'lesson_time_helper.dart';
import 'router.dart';

/// Ports Android's notification stack:
///  - GapFixApplication.updateFcmToken        -> [updateFcmToken]
///  - TutorFirebaseMessagingService           -> [_showFromRemoteMessage]
///  - LessonAlarmScheduler/LessonReminderReceiver -> [scheduleLessonReminder]
///
/// Channel ids and names match Android so the behaviour is the same.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _generalChannelId = 'gapfix_notifications';
  static const _callChannelId = 'gapfix_call_notifications';
  static const _reminderChannelId = 'gapfix_lesson_reminders';
  static const _callNotificationId = 2001; // same id Android uses for calls

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  /// Booking whose call screen is open; call pushes for it are suppressed
  /// (Android: VideoCallActivity.activeBookingId).
  String? activeBookingId;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tzdata.initializeTimeZones();

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _handleTap(response.payload),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    await FirebaseMessaging.instance.requestPermission();
    // iOS shows pushes while the app is open only if asked to.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);

    _foregroundSub = FirebaseMessaging.onMessage.listen(_showFromRemoteMessage);
    FirebaseMessaging.onMessageOpenedApp
        .listen((m) => _handleTap(_payloadFor(m.data)));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleTap(_payloadFor(initial.data));

    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((_) => updateFcmToken());
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) updateFcmToken();
    });
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
  }

  /// Port of GapFixApplication.updateFcmToken: writes the token under
  /// whichever of Users/Student/<uid> or Users/Tutor/<uid> exists.
  Future<void> updateFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      final users = FirebaseDatabase.instance.ref('Users');
      for (final role in const ['Student', 'Tutor']) {
        final node = users.child(role).child(user.uid);
        if ((await node.get()).exists) {
          await node.child('fcmToken').set(token);
        }
      }
    } catch (e) {
      debugPrint('updateFcmToken failed: $e');
    }
  }

  // ---------------------------------------------------------------- pushes

  /// Port of TutorFirebaseMessagingService.onMessageReceived/showNotification.
  Future<void> _showFromRemoteMessage(RemoteMessage message) async {
    final data = message.data;
    if (data.isNotEmpty) {
      await showNotification(
        title: data['title'],
        body: data['message'],
        bookingId: data['bookingId'],
        isCall: data['isCall']?.toLowerCase() == 'true',
      );
    } else if (message.notification != null) {
      await showNotification(
        title: message.notification!.title,
        body: message.notification!.body,
      );
    }
  }

  Future<void> showNotification({
    String? title,
    String? body,
    String? bookingId,
    bool isCall = false,
  }) async {
    if (isCall && bookingId != null && bookingId == activeBookingId) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        isCall ? _callChannelId : _generalChannelId,
        isCall ? 'Call Notifications' : 'General Notifications',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: isCall
            ? AndroidNotificationCategory.call
            : AndroidNotificationCategory.message,
        fullScreenIntent: isCall,
        ongoing: isCall,
        autoCancel: true,
        actions: isCall
            ? const [AndroidNotificationAction('answer', 'ANSWER')]
            : null,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    final id = isCall
        ? _callNotificationId
        : DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: jsonEncode({'bookingId': bookingId, 'isCall': isCall}),
    );
  }

  String _payloadFor(Map<String, dynamic> data) => jsonEncode({
        'bookingId': data['bookingId'],
        'isCall': data['isCall']?.toString().toLowerCase() == 'true',
      });

  /// Android opens VideoCallActivity (calls) or MainActivity (everything
  /// else) with BOOKING_ID. Here a call tap fetches the booking and opens
  /// the call screen; other taps just bring the app up.
  Future<void> _handleTap(String? payload) async {
    if (payload == null) return;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final bookingId = map['bookingId'] as String?;
      if (map['isCall'] != true || bookingId == null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap =
          await FirebaseDatabase.instance.ref('Bookings/$bookingId').get();
      if (!snap.exists || snap.value is! Map) return;
      final booking = BookingModel.fromMap(bookingId, snap.value as Map);
      appRouter.push('/video-call', extra: {
        'booking': booking,
        'isStudent': booking.studentId == uid,
      });
    } catch (e) {
      debugPrint('notification tap failed: $e');
    }
  }

  // ------------------------------------------------------ lesson reminders

  /// Port of LessonAlarmScheduler.schedule: fires
  /// [LessonTimeHelper.tutorJoinWindowMinutes] before the lesson start.
  Future<void> scheduleLessonReminder(BookingModel booking) async {
    final fireAtMs = booking.timestamp -
        LessonTimeHelper.tutorJoinWindowMinutes * 60 * 1000;
    if (fireAtMs <= DateTime.now().millisecondsSinceEpoch) return;

    final when =
        tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, fireAtMs);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        'Lesson Reminders',
        channelDescription: 'Reminders fired 5 minutes before each lesson',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(),
    );
    final subject = booking.subject.isEmpty ? 'Your lesson' : booking.subject;
    final start = DateTime.fromMillisecondsSinceEpoch(booking.timestamp);
    final hh = start.hour.toString().padLeft(2, '0');
    final mm = start.minute.toString().padLeft(2, '0');
    final body = '$subject starts in 5 minutes at $hh:$mm';
    final id = booking.id.hashCode;

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id,
          '⏰ Lesson starting soon!',
          body,
          when,
          details,
          androidScheduleMode: mode,
        );
    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      // Exact alarms not permitted: Android falls back to a plain alarm.
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancelLessonReminder(String bookingId) =>
      _plugin.cancel(bookingId.hashCode);
}

/// Handler for pushes that arrive while the app is in the background or
/// terminated. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Messages that carry a `notification` payload are shown by the system;
  // data-only messages (what the Android service handled) are shown here.
  if (message.notification != null) return;
  final data = message.data;
  if (data.isEmpty) return;
  final service = NotificationService.instance;
  await service.init();
  await service.showNotification(
    title: data['title'],
    body: data['message'],
    bookingId: data['bookingId'],
    isCall: data['isCall']?.toLowerCase() == 'true',
  );
}

/// Keeps the tutor's lesson reminders in step with their bookings, like
/// BookingTutorAdapter did on bind (Android schedules for tutors only):
/// confirmed lessons are scheduled, anything else is cancelled.
final lessonReminderSyncProvider = Provider<void>((ref) {
  final bookings = ref.watch(bookingsProvider).value;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (bookings == null || uid == null) return;
  final service = NotificationService.instance;
  for (final b in bookings) {
    if (b.tutorId != uid) continue;
    if (b.status.toLowerCase() == 'confirmed') {
      service.scheduleLessonReminder(b);
    } else {
      service.cancelLessonReminder(b.id);
    }
  }
});
