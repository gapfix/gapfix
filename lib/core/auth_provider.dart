import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../models/user_model.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final databaseProvider = Provider<FirebaseDatabase>((ref) => FirebaseDatabase.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  debugPrint('userProfileProvider: auth user = ${user?.uid}');
  if (user == null) return null;

  final db = ref.watch(databaseProvider);

  bool isValidProfile(Map<dynamic, dynamic> map) {
    if (map.containsKey('role') && map['role'] is String) return true;
    if (map.containsKey('email') && map['email'] is String) return true;
    if (map.containsKey('name') && map['name'] is String) return true;
    return false;
  }
  
  var snapshot = await db.ref('Users/Tutor/${user.uid}').get();
  debugPrint('userProfileProvider: Tutor snapshot exists=${snapshot.exists}, value=${snapshot.value}');
  if (snapshot.exists && snapshot.value is Map) {
    final map = snapshot.value as Map;
    if (isValidProfile(map)) {
      try {
        return UserModel.fromMap(map);
      } catch (e) {
        debugPrint('userProfileProvider: Error parsing Tutor snapshot: $e');
      }
    } else {
      debugPrint('userProfileProvider: Tutor snapshot invalid profile data, skipping');
    }
  }

  snapshot = await db.ref('Users/Student/${user.uid}').get();
  debugPrint('userProfileProvider: Student snapshot exists=${snapshot.exists}, value=${snapshot.value}');
  if (snapshot.exists && snapshot.value is Map) {
    final map = snapshot.value as Map;
    if (isValidProfile(map)) {
      try {
        return UserModel.fromMap(map);
      } catch (e) {
        debugPrint('userProfileProvider: Error parsing Student snapshot: $e');
      }
    } else {
      debugPrint('userProfileProvider: Student snapshot invalid profile data, skipping');
    }
  }

  // Fallback: try reading under Users/<uid> in case data shape differs
  snapshot = await db.ref('Users/${user.uid}').get();
  debugPrint('userProfileProvider: Fallback snapshot exists=${snapshot.exists}, value=${snapshot.value}');
  if (snapshot.exists && snapshot.value is Map) {
    final map = snapshot.value as Map;
    if (isValidProfile(map)) {
      try {
        return UserModel.fromMap(map);
      } catch (e) {
        debugPrint('userProfileProvider: Error parsing fallback snapshot: $e');
      }
    } else {
      debugPrint('userProfileProvider: Fallback snapshot invalid profile data, returning null');
    }
  }
  
  return null;
});

class AuthNotifier extends Notifier<AsyncValue<void>> {
  late FirebaseAuth _auth;
  late FirebaseDatabase _db;
  
  // Cloudinary config from your Java app
  final _cloudinary = CloudinaryPublic('dbugqpl3m', 'ml_default', cache: false);

  @override
  AsyncValue<void> build() {
    _auth = ref.watch(firebaseAuthProvider);
    _db = ref.watch(databaseProvider);
    return const AsyncValue.data(null);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required UserModel userModel,
    String? profileImagePath,
    Uint8List? profileImageBytes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = credential.user!.uid;
      String? imageUrl;

      if (profileImageBytes != null && kIsWeb) {
        try {
          final response = await _cloudinary.uploadFile(
            CloudinaryFile.fromByteData(
              profileImageBytes.buffer.asByteData(),
              folder: 'Users/$uid',
              resourceType: CloudinaryResourceType.Image,
              identifier: 'profile_$uid',
            ),
          );
          imageUrl = response.secureUrl;
        } catch (storageError) {
          debugPrint('Cloudinary Error: $storageError');
        }
      } else if (profileImagePath != null) {
        try {
          final response = await _cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              profileImagePath,
              folder: 'Users/$uid',
              resourceType: CloudinaryResourceType.Image,
            ),
          );
          imageUrl = response.secureUrl;
        } catch (storageError) {
          debugPrint('Cloudinary Error: $storageError');
        }
      }

      final finalUser = UserModel(
        name: userModel.name,
        email: userModel.email,
        role: userModel.role,
        dob: userModel.dob,
        phone: userModel.phone,
        gender: userModel.gender,
        bio: userModel.bio,
        imageResourceLink: imageUrl,
        isComplete: false,
        skippedRegistration: false,
        lessonsCount: 0,
        earnedMoney: 0,
      );
      
      await _db.ref('Users/${userModel.role}/$uid').set(finalUser.toMap());
      await credential.user!.sendEmailVerification();
      
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (authError) {
      state = AsyncValue.error('Auth Error: ${authError.message}', StackTrace.current);
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<void>>(AuthNotifier.new);
