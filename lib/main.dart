import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'firebase_options.dart';
import 'core/router.dart';
import 'core/theme.dart';

import 'core/auth_provider.dart';
import 'core/locale_provider.dart';
import 'core/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Android: FirebaseDatabase.setPersistenceEnabled(true) in GapFixApplication.
  if (!kIsWeb) {
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
    } catch (_) {}
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService.instance.init();
  }

  // Lock orientation to portrait on mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Restore the saved app language (port of Android LocaleHelper).
  final container = ProviderContainer();
  await container.read(localeProvider.notifier).load();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const GapFixApp(),
  ));
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
    final locale = ref.watch(localeProvider);
    ref.watch(lessonReminderSyncProvider);

    return ShadApp.router(
      title: 'GapFix',
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ru'), Locale('hy')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
