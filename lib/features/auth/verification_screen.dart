import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String role;
  const VerificationScreen({super.key, required this.role});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  bool _isLoading = false;

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        if (mounted) {
          if (widget.role == 'Student') {
            context.go('/student-preferences');
          } else {
            context.go('/tutor-subjects');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please verify your email first.')),
          );
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _resendEmail() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      try {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email resent!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 96,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 28),
              const Text(
                'Verify your email',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We've sent a verification email to your address. Please check your inbox (and spam folder) and click the link to verify.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _checkVerification,
                  child: const Text("I'VE VERIFIED MY EMAIL"),
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _resendEmail,
                child: const Text(
                  'RESEND VERIFICATION EMAIL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
