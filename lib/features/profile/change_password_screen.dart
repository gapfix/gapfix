import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/toast_utils.dart';

/// Port of Android ChangePasswordActivity.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPass = _oldController.text;
    final newPass = _newController.text;
    final confirmPass = _confirmController.text;

    // Same validation order and messages as the Android activity.
    if (oldPass.isEmpty) {
      ToastUtils.show(context, 'Please enter your current password',
          isError: true);
      return;
    }
    if (newPass.isEmpty) {
      ToastUtils.show(context, 'Please enter a new password', isError: true);
      return;
    }
    if (newPass.length < 6) {
      ToastUtils.show(context, 'Password must be at least 6 characters',
          isError: true);
      return;
    }
    if (newPass != confirmPass) {
      ToastUtils.show(context, 'Passwords do not match', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).changePassword(
            oldPassword: oldPass,
            newPassword: newPass,
          );
      if (!mounted) return;
      ToastUtils.show(context, 'Password Updated Successfully');
      context.pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Re-auth failures mean the old password was wrong (Android message).
      final reauthFailed = e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials';
      ToastUtils.show(
        context,
        reauthFailed
            ? 'Authentication failed: Incorrect old password'
            : 'Error: ${e.message ?? 'Update failed'}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _oldController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 32),
            if (_loading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _submit,
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    side: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  child: const Text(
                    'UPDATE PASSWORD',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
