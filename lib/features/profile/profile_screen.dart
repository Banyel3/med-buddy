import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/medication_provider.dart';
import '../../shared/widgets/medbuddy_scaffold.dart';
import '../../shared/widgets/primary_button.dart';
import 'theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final supaUser = ref.watch(currentSupabaseUserProvider);
    final meds = ref.watch(medicationsProvider).valueOrNull ?? const [];
    final themeMode = ref.watch(themeModeProvider);
    final linkCode = supaUser != null
        ? 'MB-${supaUser.id.substring(0, 6).toUpperCase()}'
        : 'MB-XXXXXX';

    return SafeArea(
      child: SingleChildScrollView(
        padding: pagePadding(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Profile',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppDimensions.space24),
              _Card(
                children: [
                  _Row(
                    icon: Icons.person_rounded,
                    label: 'Name',
                    value: user?.name.isNotEmpty == true ? user!.name : '—',
                  ),
                  _Row(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: supaUser?.email ?? '—',
                  ),
                  _Row(
                    icon: Icons.language_rounded,
                    label: 'Timezone',
                    value: user?.timezone ?? 'Asia/Manila',
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
              _Card(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.qr_code_rounded,
                          color: AppColors.primary),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Monitor link code',
                                style: Theme.of(context).textTheme.labelLarge),
                            Text(linkCode,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: linkCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
              _Card(
                children: [
                  Text('Medications',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppDimensions.space12),
                  if (meds.isEmpty)
                    Text('No medications yet.',
                        style: Theme.of(context).textTheme.bodyMedium)
                  else
                    ...meds.map((m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.medication_rounded,
                                  color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(child: Text(m.name)),
                              Text(m.scheduleTime.format(context),
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        )),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
              _Card(
                children: [
                  Text('Preferences',
                      style: Theme.of(context).textTheme.titleMedium),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark mode'),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (v) => ref
                        .read(themeModeProvider.notifier)
                        .set(v ? ThemeMode.dark : ThemeMode.light),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Credits & licenses'),
                    onTap: () => context.goNamed(AppRoute.credits),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space24),
              PrimaryButton(
                label: 'Sign out',
                icon: Icons.logout_rounded,
                gradient: false,
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) context.goNamed(AppRoute.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
