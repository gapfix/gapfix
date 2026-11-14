import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_provider.dart';
import '../../core/locale_provider.dart';
import '../../core/theme.dart';
import '../../core/toast_utils.dart';
import '../../l10n/app_strings.dart';

/// Port of Android StudentSettingsFragment and TutorSettingsFragment.
/// Both screens share name/email/avatar, language, about and logout; they
/// differ in the middle group (student: change subjects; tutor: manage
/// subjects and certificates).
class SettingsScreen extends ConsumerWidget {
  final bool isStudent;
  const SettingsScreen({super.key, required this.isStudent});

  String get _role => isStudent ? 'Student' : 'Tutor';

  Future<void> _showLanguageSheet(BuildContext context, WidgetRef ref) async {
    final current = Localizations.localeOf(context).languageCode;
    var selected = AppStrings.supportedLanguageCodes.contains(current)
        ? current
        : 'en';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Same order as Android's sheet: Armenian, English, Russian.
                for (final code in const ['hy', 'en', 'ru'])
                  RadioListTile<String>(
                    value: code,
                    groupValue: selected,
                    title: Text(AppStrings.languageName(code)),
                    onChanged: (v) => setSheetState(() => selected = v!),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      if (selected != current) {
                        ref.read(localeProvider.notifier).setLanguage(selected);
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(ctx.tr('cont')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authNotifierProvider.notifier).signOut();
    if (context.mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final authUser = ref.watch(authStateProvider).value;
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('ext_settings'))),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (user) {
          final name = (user?.name.isNotEmpty ?? false) ? user!.name : _role;
          final image = user?.imageResourceLink;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: (image != null && image.isNotEmpty)
                        ? CachedNetworkImageProvider(image)
                        : null,
                    child: (image == null || image.isEmpty)
                        ? const Icon(Icons.person, size: 36)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(authUser?.email ?? user?.email ?? '',
                            style: const TextStyle(
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/edit-profile/$_role'),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _SectionLabel(context.tr(isStudent ? 'ext_learning' : 'ext_professional')),
              if (isStudent)
                _Item(
                  icon: Icons.menu_book_outlined,
                  title: context.tr('ext_change_subjects'),
                  onTap: () => context.push('/student-preferences'),
                )
              else ...[
                _Item(
                  icon: Icons.menu_book_outlined,
                  title: context.tr('ext_manage_subjects'),
                  onTap: () => context.push('/manage-subjects'),
                ),
                _Item(
                  icon: Icons.workspace_premium_outlined,
                  title: context.tr('ext_certificates_and_resume'),
                  onTap: () => context.push('/add-certificates'),
                ),
              ],
              const SizedBox(height: 16),
              _SectionLabel(context.tr('ext_support')),
              _Item(
                icon: Icons.language,
                title: '${context.tr('ext_auto_app_language')} '
                    '(${AppStrings.languageName(langCode)})',
                onTap: () => _showLanguageSheet(context, ref),
              ),
              _Item(
                icon: Icons.info_outline,
                title: context.tr('ext_about_gapfix'),
                onTap: () => ToastUtils.show(context, 'GapFix v 1.0'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context, ref),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(context.tr('ext_logout'),
                      style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      );
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _Item({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      );
}
