import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/toast_utils.dart';

/// Port of Android EditProfileActivity.
/// [role] is "Student" or "Tutor" (the Android ROLE intent extra).
class EditProfileScreen extends ConsumerStatefulWidget {
  final String role;
  const EditProfileScreen({super.key, required this.role});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const _genders = ['Male', 'Female', 'Other'];

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _gender;
  String _countryCode = 'US';
  String _fullPhone = '';
  bool _phoneValid = true;
  String _currentImageUrl = '';
  File? _pickedImage;
  bool _loading = true;
  bool _submitted = false;

  bool get _isTutor => widget.role == 'Tutor';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      if (mounted) context.pop();
      return;
    }
    try {
      final snapshot = await ref
          .read(databaseProvider)
          .ref('Users/${widget.role}/${user.uid}')
          .get();
      if (!mounted) return;
      if (snapshot.exists && snapshot.value is Map) {
        final map = snapshot.value as Map;
        final fullName = (map['name'] as String?) ?? '';
        final parts = fullName.split(' ');
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
        _emailController.text = (map['email'] as String?) ?? '';
        _bioController.text = (map['bio'] as String?) ?? '';
        _dobController.text = (map['dob'] as String?) ?? '';
        final gender = map['gender'] as String?;
        if (gender != null && _genders.contains(gender)) _gender = gender;
        _currentImageUrl = (map['imageResourceLink'] as String?) ?? '';
        _applyStoredPhone((map['phone'] as String?) ?? '');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Splits a stored "+<dial><national>" number into country + national part
  /// (Android used CountryCodePicker.setFullNumber for this).
  void _applyStoredPhone(String stored) {
    if (stored.isEmpty) return;
    final digits = stored.startsWith('+') ? stored.substring(1) : stored;
    Country? best;
    for (final c in countries) {
      if (digits.startsWith(c.dialCode) &&
          (best == null || c.dialCode.length > best.dialCode.length)) {
        best = c;
      }
    }
    if (best != null) {
      _countryCode = best.code;
      _phoneController.text = digits.substring(best.dialCode.length);
    } else {
      _phoneController.text = digits;
    }
    _fullPhone = stored.startsWith('+') ? stored : '+$stored';
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    try {
      if (_dobController.text.isNotEmpty) {
        initial = DateFormat('dd/MM/yyyy').parseStrict(_dobController.text);
      }
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Date of Birth',
    );
    if (picked != null) {
      _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {});
    }
  }

  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(source: source);
    if (file != null) setState(() => _pickedImage = File(file.path));
  }

  Future<void> _save() async {
    setState(() => _submitted = true);

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final bio = _bioController.text.trim();
    final dob = _dobController.text.trim();

    var hasError = false;
    if (firstName.isEmpty || lastName.isEmpty || dob.isEmpty) hasError = true;
    if (_isTutor) {
      if (bio.isEmpty) hasError = true;
      if (_currentImageUrl.isEmpty && _pickedImage == null) {
        ToastUtils.show(context, 'Profile picture is required for Tutors',
            isError: true);
        hasError = true;
      }
    }
    if (_gender == null) hasError = true;
    if (hasError) {
      ToastUtils.show(context, 'Please fill in all required fields',
          isError: true);
      return;
    }
    if (_fullPhone.isEmpty || !_phoneValid) {
      ToastUtils.show(context, 'Please enter a valid phone number',
          isError: true);
      return;
    }

    setState(() => _loading = true);
    final notifier = ref.read(authNotifierProvider.notifier);
    try {
      var imageUrl = _currentImageUrl;
      if (_pickedImage != null) {
        try {
          imageUrl = await notifier.uploadProfileImage(_pickedImage!.path);
        } catch (_) {
          // Android falls back to the existing image when the upload fails.
        }
      }
      await notifier.updateProfile(role: widget.role, updates: {
        'name': '$firstName $lastName',
        'email': _emailController.text.trim(),
        'bio': bio,
        'phone': _fullPhone,
        'dob': dob,
        'gender': _gender,
        'imageResourceLink': imageUrl,
      });
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      ToastUtils.show(context, 'Profile updated');
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ToastUtils.show(context, 'Failed to update profile', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently removes your account and data. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    final notifier = ref.read(authNotifierProvider.notifier);
    try {
      await notifier.deleteAccount(widget.role);
      if (!mounted) return;
      ToastUtils.show(context, 'Account deleted');
      context.go('/');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        // Android signs the user out so they can log in again and retry.
        ToastUtils.show(
            context, 'Please log in again before deleting your account',
            isError: true);
        await notifier.signOut();
        if (mounted) context.go('/');
      } else {
        ToastUtils.show(context, 'Failed to delete account: ${e.message}',
            isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      ToastUtils.show(context, 'Failed to delete database records',
          isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration(String label, {bool error = false}) {
    return InputDecoration(
      labelText: label,
      enabledBorder: error
          ? const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent))
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatar;
    if (_pickedImage != null) {
      avatar = FileImage(_pickedImage!);
    } else if (_currentImageUrl.isNotEmpty) {
      avatar = NetworkImage(_currentImageUrl);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: avatar,
                        child: avatar == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: FloatingActionButton.small(
                          heroTag: 'editPhoto',
                          onPressed: _chooseImageSource,
                          child: const Icon(Icons.edit),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _firstNameController,
                  decoration: _decoration('First Name',
                      error: _submitted &&
                          _firstNameController.text.trim().isEmpty),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lastNameController,
                  decoration: _decoration('Last Name',
                      error: _submitted &&
                          _lastNameController.text.trim().isEmpty),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoration('Email Address'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: _decoration('Date of Birth',
                          error: _submitted && _dobController.text.isEmpty)
                      .copyWith(
                          suffixIcon:
                              const Icon(Icons.calendar_today_outlined)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration:
                      _decoration('Gender', error: _submitted && _gender == null),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 16),
                // Rebuilt when loading finishes so the stored number is shown.
                IntlPhoneField(
                  key: ValueKey('phone-$_loading-$_countryCode'),
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  initialCountryCode: _countryCode,
                  onChanged: (phone) {
                    _fullPhone = phone.completeNumber;
                    _phoneValid = phone.isValidNumber();
                  },
                ),
                if (_isTutor) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioController,
                    maxLines: 4,
                    decoration: _decoration('Bio',
                        error:
                            _submitted && _bioController.text.trim().isEmpty),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _save,
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                      side: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                    child: const Text('SAVE CHANGES',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.push('/change-password'),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Change Password'),
                ),
                TextButton.icon(
                  onPressed: _loading ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete Account',
                      style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
