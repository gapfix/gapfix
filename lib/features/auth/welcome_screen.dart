import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Language Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 16),
                child: Material(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      // TODO: Language picker
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'English',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const Spacer(flex: 2),
            
            // Logo
            Image.asset(
              'assets/images/logo.png',
              height: 220,
              width: 220,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const FlutterLogo(size: 100),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mind the gap, fix the...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary,
                letterSpacing: 0.05,
              ),
            ),
            
            const Spacer(flex: 3),
            
            // Action Container
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Google Button
                  _buildGoogleButton(context),
                  const SizedBox(height: 16),
                  
                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.slateDark)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.slateDark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Login Button
                  ElevatedButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('LOG IN'),
                  ),
                  const SizedBox(height: 12),
                  
                  // Sign Up Button
                  OutlinedButton(
                    onPressed: () => context.push('/signup-role'),
                    child: const Text('CREATE ACCOUNT'),
                  ),
                  const SizedBox(height: 12),
                  
                  // Test Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.slateDark, width: 1.2),
                            foregroundColor: AppTheme.textSecondary,
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Test Student'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.slateDark, width: 1.2),
                            foregroundColor: AppTheme.textSecondary,
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Test Tutor'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Implement Google Sign In
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8DDD9)),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 24),
              child: Icon(Icons.g_mobiledata, size: 32, color: Colors.blue), // Use a real google icon asset if possible
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 48), // Balancing the icon padding
                  child: Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: AppTheme.textDark.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
