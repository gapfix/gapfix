import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'firebase_options.dart';
import 'core/router.dart';
import 'core/theme.dart';

import 'core/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock orientation to portrait on mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
    final authState = ref.watch(authStateProvider);

    return ShadApp.router(
      title: 'GapFix',
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      materialThemeBuilder: (context, shadTheme) {
        return shadTheme.brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
      },
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light(),
      ),
    );
  }
}
