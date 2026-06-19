import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/router.dart';
import 'core/theme.dart';

import 'core/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: GapFixApp()));
}

class GapFixApp extends ConsumerWidget {
  const GapFixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Set task switcher description (Recents menu icon/color)
    SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(
        label: 'GapFix',
        primaryColor: 0xFF008253, // Brand green
      ),
    );

    // Listen to auth state to handle global navigation if needed
    // but go_router can also handle this.
    final authState = ref.watch(authStateProvider);

    return MaterialApp.router(
      title: 'GapFix',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return authState.when(
          data: (user) {
            // You could use this to show global loading or sync user data
            return child!;
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
        );
      },
    );
  }
}
