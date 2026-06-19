import 'package:go_router/go_router.dart';
import '../features/auth/welcome_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_role_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/verification_screen.dart';
import '../features/onboarding/student_preferences_screen.dart';
import '../features/onboarding/tutor_subjects_screen.dart';
import '../features/onboarding/add_certificates_screen.dart';
import '../features/home/main_layout.dart';
import '../features/home/library_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup-role',
      builder: (context, state) => const SignUpRoleScreen(),
    ),
    GoRoute(
      path: '/signup/:role',
      builder: (context, state) {
        final role = state.pathParameters['role']!;
        return SignUpScreen(role: role);
      },
    ),
    GoRoute(
      path: '/verification/:role',
      builder: (context, state) {
        final role = state.pathParameters['role']!;
        return VerificationScreen(role: role);
      },
    ),
    GoRoute(
      path: '/student-preferences',
      builder: (context, state) => const StudentPreferencesScreen(),
    ),
    GoRoute(
      path: '/tutor-subjects',
      builder: (context, state) => const TutorSubjectsScreen(),
    ),
    GoRoute(
      path: '/add-certificates',
      builder: (context, state) => const AddCertificatesScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const MainLayout(),
    ),
    GoRoute(
      path: '/library',
      name: 'library',
      builder: (context, state) => const LibraryScreen(),
    ),
  ],
);




