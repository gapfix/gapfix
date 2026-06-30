import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/student_tutor_display_model.dart';
import 'widgets/tutor_card_widget.dart';

class StudentTutorsScreen extends StatefulWidget {
  const StudentTutorsScreen({super.key});

  @override
  State<StudentTutorsScreen> createState() => _StudentTutorsScreenState();
}

class _StudentTutorsScreenState extends State<StudentTutorsScreen> {
  final List<StudentTutorDisplayModel> _tutorList = [];
  final Map<String, StudentTutorDisplayModel> _tutorMap = {};
  String? _currentUserId;
  
  late DatabaseReference _bookingsRef;
  late DatabaseReference _usersRef;
  late FirebaseFirestore _db;
  
  StreamSubscription? _bookingsSubscription;
  StreamSubscription? _chatsSubscription;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _db = FirebaseFirestore.instance;
    _bookingsRef = FirebaseDatabase.instance.ref("Bookings");
    _usersRef = FirebaseDatabase.instance.ref("Users");
    
    _loadTutors();
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    _chatsSubscription?.cancel();
    super.dispose();
  }

  void _loadTutors() {
    if (_currentUserId == null) return;

    _usersRef.child("Student").child(_currentUserId!).once().then((DatabaseEvent event) {
      if (!event.snapshot.exists) {
        setState(() {
          _tutorMap.clear();
          _updateList();
        });
        return;
      }
      _startLoadingData();
    });
  }

  void _startLoadingData() {
    _bookingsSubscription = _bookingsRef.onValue.listen((event) {
      if (event.snapshot.value == null) return;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final Map<String, bool> futureLessonMap = {};
      
      final dynamic data = event.snapshot.value;
      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            final bookingMap = Map<String, dynamic>.from(value);
            String? sId = bookingMap['studentId']?.toString() ?? bookingMap['studentID']?.toString();
            
            if (_currentUserId == sId) {
              String? tId = bookingMap['tutorId']?.toString() ?? 
                           bookingMap['teacherId']?.toString() ?? 
                           bookingMap['teacherID']?.toString();
              if (tId != null) {
                int? ts = bookingMap['timestamp'] is int ? bookingMap['timestamp'] : null;
                if (ts != null && ts > now) {
                  String? status = bookingMap['status']?.toString();
                  if (status?.toLowerCase() != 'cancelled') {
                    futureLessonMap[tId] = true;
                  }
                }
                if (!futureLessonMap.containsKey(tId)) {
                  futureLessonMap[tId] = false;
                }
                if (!_tutorMap.containsKey(tId)) {
                  _addTutorToMap(tId);
                }
              }
            }
          }
        });
      }

      futureLessonMap.forEach((tId, hasFutureLesson) {
        if (_tutorMap.containsKey(tId)) {
          _tutorMap[tId]!.canDelete = !hasFutureLesson;
        }
      });
      _updateList();
    });

    _chatsSubscription = _db.collection("chats")
        .where("participants", arrayContains: _currentUserId)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        for (var id in participants) {
          if (id != _currentUserId) {
            if (!_tutorMap.containsKey(id)) {
              _addTutorToMap(id);
            }
            final tm = _tutorMap[id];
            if (tm != null) {
              tm.chatId = doc.id;
              int chatUnread = _getFirestoreCount(data, "unreadChatCount", _currentUserId!);
              int hwUnread = _getFirestoreCount(data, "unreadHomeworkCount", _currentUserId!);
              tm.unreadChatCount = chatUnread;
              tm.unreadHomeworkCount = hwUnread;
              tm.unreadCount = chatUnread + hwUnread;

              if (chatUnread == 0 && hwUnread == 0) {
                 tm.unreadCount = _getFirestoreCount(data, "unreadCount", _currentUserId!);
              }
            }
          }
        }
      }
      _updateList();
    });
  }

  int _getFirestoreCount(Map<String, dynamic> data, String field, String uid) {
    final obj = data[field];
    if (obj is Map) {
      final val = obj[uid];
      if (val is num) return val.toInt();
    }
    return 0;
  }

  void _addTutorToMap(String tutorId) {
    final tm = StudentTutorDisplayModel(
      uid: tutorId,
      canDelete: true,
    );
    _tutorMap[tutorId] = tm;
    _fetchTutorDetails(tutorId);
  }

  void _fetchTutorDetails(String tutorId) {
    _usersRef.child("Tutor").child(tutorId).once().then((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final tm = _tutorMap[tutorId];
        if (tm != null) {
          tm.name = data['name']?.toString();
          tm.email = data['email']?.toString();
          tm.profileImage = (data['imageResourceLink'] ?? data['profilePicture'])?.toString();
          _updateList();
        }
      } else {
        _tutorMap.remove(tutorId);
        _updateList();
      }
    });
  }

  void _updateList() {
    if (!mounted) return;
    setState(() {
      _tutorList.clear();
      for (var tm in _tutorMap.values) {
        if (!tm.canDelete || (tm.chatId != null && tm.chatId!.isNotEmpty)) {
          _tutorList.add(tm);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "My Tutors",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: _tutorList.isEmpty
          ? const Center(child: Text("No tutors found"))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _tutorList.length,
              itemBuilder: (context, index) {
                final tutor = _tutorList[index];
                return TutorCardWidget(
                  tutor: tutor,
                  onDelete: () => _confirmAndDeleteTutor(tutor),
                );
              },
            ),
    );
  }

  void _confirmAndDeleteTutor(StudentTutorDisplayModel tutor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Tutor"),
        content: Text("Delete chat history with ${tutor.name ?? 'this tutor'}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (tutor.chatId != null) {
                await _db.collection("chats").doc(tutor.chatId!).delete();
                setState(() {
                  tutor.chatId = null;
                  _updateList();
                });
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
