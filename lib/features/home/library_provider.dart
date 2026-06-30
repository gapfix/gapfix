import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import '../../core/auth_provider.dart';
import '../../models/archive_model.dart';

final librarySubjectsProvider = StreamProvider<List<SubjectArchiveModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  final dbRef = FirebaseDatabase.instance.ref('Users/Student/${user.uid}/Archives');
  
  return dbRef.onValue.map((event) {
    if (!event.snapshot.exists) return [];
    
    final subjectsMap = event.snapshot.value as Map<dynamic, dynamic>;
    final List<SubjectArchiveModel> subjects = [];
    
    subjectsMap.forEach((subjectName, filesMap) {
      if (filesMap is Map) {
        int total = 0;
        int reviewed = 0;
        filesMap.forEach((_, fileData) {
          if (fileData is Map) {
            total++;
            if (fileData['reviewed'] == true) {
              reviewed++;
            }
          }
        });
        subjects.add(SubjectArchiveModel(
          subjectName: subjectName.toString(),
          totalFiles: total,
          reviewedCount: reviewed,
        ));
      }
    });
    
    subjects.sort((a, b) => a.subjectName.compareTo(b.subjectName));
    return subjects;
  });
});

final subjectFilesProvider = StreamProvider.family<List<ArchiveModel>, String>((ref, subject) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  final dbRef = FirebaseDatabase.instance.ref('Users/Student/${user.uid}/Archives/$subject');
  
  return dbRef.onValue.map((event) {
    if (!event.snapshot.exists) return [];
    
    final filesMap = event.snapshot.value as Map<dynamic, dynamic>;
    final List<ArchiveModel> files = [];
    
    filesMap.forEach((id, data) {
      files.add(ArchiveModel.fromMap(id.toString(), data as Map));
    });
    
    files.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return files;
  });
});

class LibraryNotifier extends Notifier<AsyncValue<void>> {
  late String _uid;
  final _cloudinary = CloudinaryPublic('dbugqpl3m', 'ml_default', cache: false);

  @override
  AsyncValue<void> build() {
    final user = ref.watch(authStateProvider).value;
    _uid = user?.uid ?? '';
    return const AsyncValue.data(null);
  }

  Future<void> uploadLibraryFile({
    required String title,
    required String subject,
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    state = const AsyncValue.loading();
    try {
      CloudinaryResponse response;
      
      final resourceType = fileName.toLowerCase().endsWith('.pdf') 
          ? CloudinaryResourceType.Auto 
          : CloudinaryResourceType.Image;

      if (kIsWeb && fileBytes != null) {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromByteData(
            fileBytes.buffer.asByteData(),
            folder: 'Archives/$_uid',
            resourceType: resourceType,
            identifier: fileName,
          ),
        );
      } else if (filePath != null) {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            filePath,
            folder: 'Archives/$_uid',
            resourceType: resourceType,
          ),
        );
      } else {
        throw Exception('No file data provided');
      }

      final archive = ArchiveModel(
        id: title,
        title: title,
        userId: _uid,
        subject: subject,
        fileUrl: response.secureUrl,
        fileName: fileName,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        reviewed: false,
      );

      await FirebaseDatabase.instance
          .ref('Users/Student/$_uid/Archives/$subject/$title')
          .set(archive.toMap());

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleReviewed(ArchiveModel item) async {
    await FirebaseDatabase.instance
        .ref('Users/Student/$_uid/Archives/${item.subject}/${item.id}/reviewed')
        .set(!item.reviewed);
  }

  Future<void> deleteLibraryFile(ArchiveModel item) async {
    await FirebaseDatabase.instance
        .ref('Users/Student/$_uid/Archives/${item.subject}/${item.id}')
        .remove();
  }
}

final libraryNotifierProvider = NotifierProvider<LibraryNotifier, AsyncValue<void>>(LibraryNotifier.new);
