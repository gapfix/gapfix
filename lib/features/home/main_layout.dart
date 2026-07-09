import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/liquid_glass_nav_bar.dart';
import '../calendar/calendar_screen.dart';
import '../shop/tutor_shop_screen.dart';
import '../chat/chat_list_screen.dart';


class TutorDashboardScreen extends ConsumerWidget {
  const TutorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    
    return userAsync.maybeWhen(
      data: (user) {
        if (user == null) return const Center(child: Text('User not found'));
        
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: user.imageResourceLink != null 
                              ? CachedNetworkImageProvider(user.imageResourceLink!) 
                              : null,
                            child: user.imageResourceLink == null ? const Icon(Icons.person) : null,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hello,', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                              Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      Row(
                        children: [
                          _buildStatCard(context, 'Earnings', '\$${user.earnedMoney.toStringAsFixed(2)}', Icons.payments_outlined, Colors.green),
                          const SizedBox(width: 16),
                          _buildStatCard(context, 'Lessons', user.lessonsCount.toString(), Icons.school_outlined, Colors.blue),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      Text('NEXT LESSON', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 12),
                      
                      _buildNextLessonCard(context),

                      const SizedBox(height: 32),
                      Text('QUICK ACTIONS', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildActionButton(context, 'Subjects', Icons.book_outlined, () => ref.read(bottomNavIndexProvider.notifier).state = 2),
                          const SizedBox(width: 12),
                          _buildActionButton(context, 'Calendar', Icons.calendar_today_outlined, () => ref.read(bottomNavIndexProvider.notifier).state = 1),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const Center(child: CircularProgressIndicator.adaptive()),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: Colors.white10) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildNextLessonCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: isDark ? 0.2 : 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.event_note, color: Colors.white, size: 48),
          SizedBox(height: 12),
          Text('No upcoming lessons', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Your schedule is empty for today', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

    return userAsync.maybeWhen(
      data: (user) {
        if (user == null) return const Center(child: Text('User not found'));
        
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hello,', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                              Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: user.imageResourceLink != null 
                              ? CachedNetworkImageProvider(user.imageResourceLink!) 
                              : null,
                            child: user.imageResourceLink == null ? const Icon(Icons.person) : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            _buildStudentStat('0.0h', 'Learning Hours'),
                            Container(width: 1, height: 40, color: Colors.white24),
                            _buildStudentStat('0', 'Active Courses'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('UPCOMING LESSON', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          TextButton(onPressed: () => context.push("/calendar"), child: const Text('See all')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      _buildEmptyLessonCard(context),


                      const SizedBox(height: 32),
                      const Text('QUICK ACTIONS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildActionButton(context, 'Library', Icons.local_library_outlined, () => context.push('/library')),
                          const SizedBox(width: 12),
                          _buildActionButton(context, 'Tutors', Icons.search, () => ref.read(bottomNavIndexProvider.notifier).state = 1),
                        ],
                      ),

                      const SizedBox(height: 32),
                      const Text('EXPLORE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 12),
                      _buildExploreCard(context, 'Find a Tutor', 'Browse experts in your interested subjects', Icons.search, () {
                        ref.read(bottomNavIndexProvider.notifier).state = 1;
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const Center(child: CircularProgressIndicator.adaptive()),
    );
  }

  Widget _buildStudentStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildEmptyLessonCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined, size: 48, color: isDark ? Colors.white24 : Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No lessons scheduled', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: Colors.white10) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}


// Fixed placeholders for all nav items
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text(title)),
  );
}

class BottomNavIndex extends Notifier<int> {
  @override
  int build() => 0;
  @override
  set state(int value) => super.state = value;
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndex, int>(BottomNavIndex.new);

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('User not found')));

        final isTutor = user.role.toLowerCase() == 'tutor';
        debugPrint('DEBUG MainLayout - Role: "${user.role}","${user.email}", isTutor: $isTutor');
        final items = isTutor ? _tutorNavItems : _studentNavItems;
        final screens = isTutor ? _tutorScreens : _studentScreens;

        final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
        final liquidItems = isTutor ? _tutorLiquidItems : _studentLiquidItems;

        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: screens,
          ),
          bottomNavigationBar: isIOS
              ? LiquidGlassNavBar(
                  currentIndex: selectedIndex,
                  onTap: (index) => ref.read(bottomNavIndexProvider.notifier).state = index,
                  items: liquidItems,
                )
              : Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    currentIndex: selectedIndex,
                    onTap: (index) => ref.read(bottomNavIndexProvider.notifier).state = index,
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: AppTheme.primary,
                    unselectedItemColor: Colors.grey,
                    showUnselectedLabels: true,
                    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    unselectedLabelStyle: const TextStyle(fontSize: 11),
                    items: items,
                  ),
                ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator.adaptive())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  List<BottomNavigationBarItem> get _tutorNavItems => const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Calendar'),
    BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'Subjects'),
    BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
  ];

  List<BottomNavigationBarItem> get _studentNavItems => const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.search), activeIcon: Icon(Icons.search), label: 'Tutors'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Calendar'),
    BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
  ];

  List<Widget> get _tutorScreens => const [
    TutorDashboardScreen(),
    CalendarScreen(isStudent: false),
    PlaceholderScreen(title: 'My Subjects'),
    ChatListScreen(),
    PlaceholderScreen(title: 'Tutor Settings'),
  ];

  List<Widget> get _studentScreens => const [
    StudentDashboardScreen(),
    TutorShopScreen(),
    CalendarScreen(isStudent: true),
    ChatListScreen(),
    PlaceholderScreen(title: 'Student Settings'),
  ];

  List<LiquidGlassNavItem> get _tutorLiquidItems => const [
    LiquidGlassNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    LiquidGlassNavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Calendar'),
    LiquidGlassNavItem(icon: Icons.book_outlined, activeIcon: Icons.book, label: 'Subjects'),
    LiquidGlassNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chat'),
    LiquidGlassNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  List<LiquidGlassNavItem> get _studentLiquidItems => const [
    LiquidGlassNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    LiquidGlassNavItem(icon: Icons.search, activeIcon: Icons.search, label: 'Tutors'),
    LiquidGlassNavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Calendar'),
    LiquidGlassNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chat'),
    LiquidGlassNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];
}

