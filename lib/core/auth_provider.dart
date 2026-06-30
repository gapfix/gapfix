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
  if (user == null) return null;

  final db = ref.watch(databaseProvider);
  
  var snapshot = await db.ref('Users/Student/${user.uid}').get();
  if (snapshot.exists) {
    return UserModel.fromMap(snapshot.value as Map);
  }
  
  snapshot = await db.ref('Users/Tutor/${user.uid}').get();
  if (snapshot.exists) {
    return UserModel.fromMap(snapshot.value as Map);
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
