import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../models/booking_model.dart';
import 'package:go_router/go_router.dart';

const String appId = '2a52ca8890ac482d95808a709a697573';

class VideoCallScreen extends StatefulWidget {
  final BookingModel booking;
  final bool isStudent;

  const VideoCallScreen({
    super.key,
    required this.booking,
    required this.isStudent,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  
  Timer? _classTimer;
  int _remainingSeconds = 0;
  bool _isEnding = false;

  late DatabaseReference _callRef;
  late DatabaseReference _bookingRef;
  StreamSubscription? _callSub;
  StreamSubscription? _bookingSub;

  @override
  void initState() {
    super.initState();
    _callRef = FirebaseDatabase.instance.ref('Calls').child(widget.booking.id);
    _bookingRef = FirebaseDatabase.instance.ref('Bookings').child(widget.booking.id);
    
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create RtcEngine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // Register event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('Local user joined');
          setState(() => _localUserJoined = true);
          _startClassTimer();
          _updateCallState('calling');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('Remote user joined: $remoteUid');
          setState(() {
            _remoteUid = remoteUid;
          });
          _updateCallState('answered');
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint('Remote user offline: $remoteUid');
          setState(() {
            _remoteUid = null;
          });
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('Agora Error: $err - $msg');
        },
      ),
    );

    // Enable video
    await _engine.enableVideo();
    await _engine.startPreview();

    // Set role
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // Join channel (using booking ID as channel name)
    await _engine.joinChannel(
      token: '', // No token used for testing based on provided code
      channelId: widget.booking.id,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    _listenForFirebaseChanges();
  }

  void _listenForFirebaseChanges() {
    _callSub = _callRef.onValue.listen((event) {
      if (_isEnding) return;
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final state = data['state'];
        if (state == 'ended' || state == 'cancelled' || state == 'declined') {
          _finalizeCall();
        } else if (state == 'offline') {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_isEnding) _leaveCall();
          });
        }
      }
    });

    _bookingSub = _bookingRef.onValue.listen((event) {
      if (_isEnding) return;
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (data['status'] == 'finished') {
          _finalizeCall();
        } else if (data['finishRequests'] != null) {
          final finishRequests = Map<String, dynamic>.from(data['finishRequests'] as Map);
          if (finishRequests.length >= 2) {
            _finalizeCall();
          }
        }
      }
    });
  }

  void _updateCallState(String state) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _callRef.update({
      'state': state,
      'callerId': ?uid,
    });
  }

  void _startClassTimer() {
    final scheduledStart = widget.booking.timestamp;
    final durationMins = widget.booking.duration;
    
    final scheduledEnd = scheduledStart + (durationMins * 60 * 1000);
    final remainingMs = scheduledEnd - DateTime.now().millisecondsSinceEpoch;
    
    if (remainingMs <= 0) {
      _finalizeCall();
      return;
    }

    setState(() {
      _remainingSeconds = remainingMs ~/ 1000;
    });

    _classTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _finalizeCall();
        }
      });
    });
  }

  Future<void> _finishLessonAction() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    await _bookingRef.child('finishRequests').child(uid).set(true);
    
    if (!widget.isStudent) {
      // Tutor finishing lesson
      final snapshot = await _bookingRef.child('finishRequests').child(widget.booking.studentId).get();
      if (snapshot.value == false || snapshot.value == null) {
        // Wait for student
        if (mounted) {
          ShadToaster.of(context).show(
            const ShadToast(description: Text('Waiting for student to finish...')),
          );
        }
      }
    }
  }

  Future<void> _finalizeCall() async {
    if (_isEnding) return;
    setState(() => _isEnding = true);
    
    _classTimer?.cancel();
    
    if (!widget.isStudent) {
      // Update booking to finished
      await _bookingRef.update({'status': 'finished'});
    }
    
    _updateCallState('ended');
    _leaveCall();
  }

  Future<void> _leaveCall() async {
    _classTimer?.cancel();
    _callSub?.cancel();
    _bookingSub?.cancel();
    
    await _engine.stopPreview();
    await _engine.leaveChannel();
    await _engine.release();
    
    if (mounted) {
      context.pop();
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _classTimer?.cancel();
    _callSub?.cancel();
    _bookingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video
            Center(
              child: _remoteUid != null
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _engine,
                        canvas: VideoCanvas(uid: _remoteUid),
                        connection: RtcConnection(channelId: widget.booking.id),
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Waiting for other user to join...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
            ),
            
            // Timer
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Local Video
            Positioned(
              top: 16,
              right: 16,
              child: SizedBox(
                width: 120,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _localUserJoined
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : const ColoredBox(color: Colors.black54),
                ),
              ),
            ),

            // Controls
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.red : Colors.white,
                    iconColor: _isMuted ? Colors.white : Colors.black,
                    onTap: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                      _engine.muteLocalAudioStream(_isMuted);
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildControlButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    iconColor: Colors.white,
                    onTap: () {
                      _updateCallState('offline');
                      _leaveCall();
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildControlButton(
                    icon: Icons.check,
                    color: Colors.green,
                    iconColor: Colors.white,
                    onTap: _finishLessonAction,
                  ),
                  const SizedBox(width: 16),
                  _buildControlButton(
                    icon: Icons.flip_camera_ios,
                    color: Colors.white,
                    iconColor: Colors.black,
                    onTap: () {
                      _engine.switchCamera();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 28,
        ),
      ),
    );
  }
}
