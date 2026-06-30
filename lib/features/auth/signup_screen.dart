import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/adaptive_utils.dart';
import '../../core/toast_utils.dart';
import '../../models/user_model.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  final String role;
  const SignUpScreen({super.key, required this.role});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _bioController = TextEditingController();
  final _dobController = TextEditingController();
  
  String? _gender;
  String? _phone;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _agreeTerms = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
        });
      } else {
        setState(() => _imageFile = pickedFile);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await AdaptiveUtils.showAdaptiveDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeTerms) {
      ToastUtils.show(context, 'Please agree to terms and conditions', isError: true);
      return;
    }

    if (widget.role == 'Tutor' && _imageFile == null) {
      ToastUtils.show(context, 'Profile picture is required for tutors', isError: true);
      return;
    }

    final userModel = UserModel(
      name: '${_firstNameController.text} ${_lastNameController.text}',
      email: _emailController.text,
      role: widget.role,
      dob: _dobController.text,
      phone: _phone,
      gender: _gender,
      bio: widget.role == 'Tutor' ? _bioController.text : null,
      isComplete: false,
    );

    await ref.read(authNotifierProvider.notifier).signUp(
      email: _emailController.text,
      password: _passwordController.text,
      userModel: userModel,
      profileImagePath: kIsWeb ? null : _imageFile?.path,
      profileImageBytes: _imageBytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      next.when(
        data: (_) {
          context.go('/verification/${widget.role}');
        },
        loading: () {},
        error: (e, s) {
          ToastUtils.show(context, e.toString(), isError: true);
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text('Join as ${widget.role}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: _imageBytes != null 
                        ? MemoryImage(_imageBytes!) 
                        : (_imageFile != null && !kIsWeb 
                           ? NetworkImage(_imageFile!.path) // This is not quite right for File but ImagePicker handles paths
                           : null),
                      child: _imageFile == null 
                        ? const Icon(Icons.person_outline, size: 60, color: AppTheme.slateDark) 
                        : null,
                    ),
                    // Use a better way to show image if not on Web and not bytes
                    if (_imageFile != null && !kIsWeb && _imageBytes == null)
                      ClipOval(
                        child: Image.network( // In Flutter Web/Mobile XFile.path works differently
                          _imageFile!.path,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.person),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primary,
                          child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              IntlPhoneField(
                decoration: const InputDecoration(labelText: 'Phone Number'),
                initialCountryCode: 'US',
                onChanged: (phone) => _phone = phone.completeNumber,
              ),
              const SizedBox(height: 16),

              if (widget.role == 'Tutor') ...[
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    helperText: 'Tell students about yourself (min. 30 chars)',
                  ),
                  validator: (v) => (v!.length < 30) ? 'Bio too short' : null,
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordConfirmController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (v) => v != _passwordController.text ? 'Passwords match fail' : null,
              ),
              const SizedBox(height: 24),

              CheckboxListTile.adaptive(
                value: _agreeTerms,
                onChanged: (v) => setState(() => _agreeTerms = v!),
                title: const Text('I agree to the Terms and Conditions'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              if (authState.isLoading)
                const CircularProgressIndicator.adaptive()
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('CREATE ACCOUNT'),
                ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
