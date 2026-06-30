import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:gapfix/core/file_opener.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';

class AddCertificatesScreen extends ConsumerStatefulWidget {
  const AddCertificatesScreen({super.key});

  @override
  ConsumerState<AddCertificatesScreen> createState() => _AddCertificatesScreenState();
}

class _AddCertificatesScreenState extends ConsumerState<AddCertificatesScreen> {
  final List<Map<String, dynamic>> _uploadedCertificates = [];
  bool _isLoadingCerts = true;
  bool _isUploading = false;
  Uint8List? _selectedFileBytes;
  String? _selectedFilePath;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      final dbRef = FirebaseDatabase.instance.ref('Users/Tutor/${user.uid}/Certificates');
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        setState(() {
          _uploadedCertificates.clear();
          data.forEach((key, value) {
            final cert = Map<String, dynamic>.from(value as Map);
            cert['id'] = key;
            _uploadedCertificates.add(cert);
          });
        });
      }
    } catch (e) {
      debugPrint('Error loading certificates: $e');
    } finally {
      setState(() => _isLoadingCerts = false);
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

  Future<void> _uploadCertificate() async {
    if ((_selectedFilePath == null && _selectedFileBytes == null) || _isUploading) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final cloudinary = CloudinaryPublic('dbugqpl3m', 'ml_default', cache: false);
      CloudinaryResponse response;
      
      final resourceType = _fileName!.toLowerCase().endsWith('.pdf') 
          ? CloudinaryResourceType.Auto 
          : CloudinaryResourceType.Image;

      if (kIsWeb && _selectedFileBytes != null) {
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromByteData(
            _selectedFileBytes!.buffer.asByteData(),
            folder: 'Certificates/${user.uid}',
            resourceType: resourceType,
            identifier: _fileName!,
          ),
        );
      } else {
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _selectedFilePath!,
            folder: 'Certificates/${user.uid}',
            resourceType: resourceType,
          ),
        );
      }

      final certData = {
        'name': _fileName,
        'url': response.secureUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await FirebaseDatabase.instance
          .ref('Users/Tutor/${user.uid}/Certificates')
          .push()
          .set(certData);

      _selectedFilePath = null;
      _selectedFileBytes = null;
      _fileName = null;
      await _loadCertificates();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificate uploaded successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Certificates'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('SKIP', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload your teaching certificates, degrees, or awards to build trust with students.',
              style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            
            // Picker Area
            InkWell(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(16),
                  color: AppTheme.primary.withValues(alpha: 0.05),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 48, color: AppTheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      _fileName ?? 'Tap to select a file (PDF, JPG, PNG)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            if (_fileName != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadCertificate,
                child: _isUploading 
                  ? const CircularProgressIndicator.adaptive(backgroundColor: Colors.white) 
                  : const Text('UPLOAD CERTIFICATE'),
              ),
            ],

            const SizedBox(height: 32),
            const Text('YOUR UPLOADED DOCUMENTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),

            Expanded(
              child: _isLoadingCerts 
                ? const Center(child: CircularProgressIndicator.adaptive())
                : _uploadedCertificates.isEmpty 
                  ? const Center(child: Text('No certificates uploaded yet.'))
                  : ListView.builder(
                      itemCount: _uploadedCertificates.length,
                      itemBuilder: (context, index) {
                        final cert = _uploadedCertificates[index];
                        final isPdf = cert['name'].toString().toLowerCase().endsWith('.pdf');
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: AppTheme.primary),
                            title: Text(cert['name']),
                            subtitle: Text(DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(cert['timestamp']))),
                            trailing: IconButton(
                              icon: const Icon(Icons.open_in_new),
                              onPressed: () => FileOpener.openFile(context, cert['url']),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 24),
            if (_uploadedCertificates.isNotEmpty)
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('CONTINUE TO DASHBOARD'),
              ),
          ],
        ),
      ),
    );
  }
}
