import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme.dart';
import '../../models/archive_model.dart';
import 'library_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(librarySubjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Library')),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(child: Text('Your library is empty.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final s = subjects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(s.subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text(
                    '${s.totalFiles} files • ${s.reviewedCount} reviewed',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSubjectFiles(context, s.subjectName),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLibraryFile(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showSubjectFiles(BuildContext context, String subject) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SubjectFilesBottomSheet(subject: subject),
    );
  }

  void _showAddLibraryFile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const AddLibraryFileBottomSheet(),
    );
  }
}

class SubjectFilesBottomSheet extends ConsumerWidget {
  final String subject;
  const SubjectFilesBottomSheet({super.key, required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(subjectFilesProvider(subject));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$subject Library', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          filesAsync.when(
            data: (files) {
              if (files.isEmpty) return const Text('No files in this subject.');
              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final f = files[index];
                    final isPdf = f.fileUrl.toLowerCase().contains('.pdf');
                    return ListTile(
                      leading: Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: isPdf ? Colors.red : AppTheme.primary),
                      title: Text(f.title, style: TextStyle(decoration: f.reviewed ? TextDecoration.lineThrough : null)),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(f.timestamp))),
                      onTap: () => _viewFile(context, f),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(f.reviewed ? Icons.check_circle : Icons.check_circle_outline, color: f.reviewed ? Colors.green : Colors.grey),
                            onPressed: () => ref.read(libraryNotifierProvider.notifier).toggleReviewed(f),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDelete(context, ref, f),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  void _viewFile(BuildContext context, ArchiveModel item) async {
    if (item.fileUrl.toLowerCase().contains('.pdf')) {
      final uri = Uri.parse(item.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close',
        barrierColor: Colors.black.withOpacity(0.9),
        pageBuilder: (context, anim1, anim2) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
              title: Text(item.title, style: const TextStyle(color: Colors.white)),
            ),
            body: Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: item.fileUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ArchiveModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              ref.read(libraryNotifierProvider.notifier).deleteLibraryFile(item);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AddLibraryFileBottomSheet extends ConsumerStatefulWidget {
  const AddLibraryFileBottomSheet({super.key});

  @override
  ConsumerState<AddLibraryFileBottomSheet> createState() => _AddLibraryFileBottomSheetState();
}

class _AddLibraryFileBottomSheetState extends ConsumerState<AddLibraryFileBottomSheet> {
  final _titleController = TextEditingController();
  String? _selectedSubject;
  Uint8List? _selectedFileBytes;
  String? _selectedFilePath;
  String? _fileName;
  final List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final ref = FirebaseDatabase.instance.ref('Subjects');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = snapshot.value;
      setState(() {
        if (data is List) {
          _subjects.addAll(data.whereType<String>());
        } else if (data is Map) {
          data.forEach((key, value) {
            if (value is String) _subjects.add(value);
            else if (value is Map) _subjects.add(value['en'] ?? key);
          });
        }
        _subjects.sort();
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
      withData: kIsWeb,
    );
    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        if (kIsWeb) {
          _selectedFileBytes = result.files.single.bytes;
        } else {
          _selectedFilePath = result.files.single.path;
        }
      });
    }
  }

  void _upload() async {
    if (_titleController.text.isEmpty || _selectedSubject == null || (_selectedFilePath == null && _selectedFileBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and select a file')));
      return;
    }

    await ref.read(libraryNotifierProvider.notifier).uploadLibraryFile(
      title: _titleController.text,
      subject: _selectedSubject!,
      fileName: _fileName!,
      fileBytes: _selectedFileBytes,
      filePath: _selectedFilePath,
    );
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryNotifierProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add to Library', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Chapter 1 Notes'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSubject,
            hint: const Text('Select Subject'),
            items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _selectedSubject = v),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(_fileName ?? 'SELECT FILE (JPG, PNG, PDF)'),
          ),
          const SizedBox(height: 32),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(onPressed: _upload, child: const Text('UPLOAD TO LIBRARY')),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
