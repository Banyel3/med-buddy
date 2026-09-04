import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/medication_provider.dart';
import '../../shared/providers/supabase_providers.dart';
import '../../shared/widgets/medbuddy_scaffold.dart';
import '../../shared/widgets/primary_button.dart';
import '../lock/alarm_settings_provider.dart';
import 'theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static String _alarmSubtitle({
    required bool enabled,
    required bool envPinned,
  }) {
    if (envPinned) {
      return 'Pinned by build flag / .env (MEDBUDDY_ALARM). '
          'Unset to enable this toggle.';
    }
    if (!enabled) return 'Reminders only. Your phone stays quiet.';
    return 'Rings until you verify your dose. Stops on its own after '
        "5 minutes, and you can always say you can't take it right now.";
  }

  static ValueChanged<bool> _setAlarm(WidgetRef ref) =>
      (v) => ref.read(alarmEnabledProvider.notifier).set(v);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final supaUser = ref.watch(currentSupabaseUserProvider);
    final meds = ref.watch(medicationsProvider).valueOrNull ?? const [];
    final themeMode = ref.watch(themeModeProvider);
    final alarmEnabled = ref.watch(alarmEnabledProvider);
    final alarmEnvPinned = ref.read(alarmEnabledProvider.notifier).envPinned;
    final alarmSubtitle = _alarmSubtitle(
      enabled: alarmEnabled,
      envPinned: alarmEnvPinned,
    );
    final linkCode = supaUser != null
        ? 'MB-${supaUser.id.substring(0, 6).toUpperCase()}'
        : 'MB-XXXXXX';
    final linkCodeFull = supaUser?.id ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: pagePadding(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Profile', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppDimensions.space24),
              _Card(
                children: [
                  _Row(
                    icon: Icons.person_rounded,
                    label: 'Name',
                    value: user?.name.isNotEmpty == true ? user!.name : '—',
                    onTap: supaUser == null
                        ? null
                        : () => _editName(
                            context,
                            ref,
                            userId: supaUser.id,
                            current: user?.name ?? '',
                          ),
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
                    onTap: supaUser == null
                        ? null
                        : () => _editTimezone(
                            context,
                            ref,
                            userId: supaUser.id,
                            current: user?.timezone ?? 'Asia/Manila',
                          ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
              _Card(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.qr_code_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Link code',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              linkCode,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (linkCodeFull.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'or paste: $linkCodeFull',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        tooltip: 'Copy full link code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: linkCodeFull));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Link code copied — paste it into the web dashboard',
                              ),
                            ),
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
                  Text(
                    'Medications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  if (meds.isEmpty)
                    Text(
                      'No medications yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ...meds.map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.medication_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(m.name)),
                            Text(
                              m.scheduleTime.format(context),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
              _Card(
                children: [
                  Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark mode'),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (v) => ref
                        .read(themeModeProvider.notifier)
                        .set(v ? ThemeMode.dark : ThemeMode.light),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dose alarm'),
                    subtitle: Text(
                      alarmSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: alarmEnabled,
                    onChanged: alarmEnvPinned ? null : _setAlarm(ref),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.outline,
              size: 18,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }
}

Future<void> _editName(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String current,
}) async {
  final ctrl = TextEditingController(text: current);
  final next = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit name'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (next == null || next.isEmpty || next == current) return;
  await ref
      .read(supabaseServiceProvider)
      .updateUserProfile(userId: userId, name: next);
  ref.invalidate(currentUserProvider);
}

Future<void> _editTimezone(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String current,
}) async {
  const options = <String>[
    'Asia/Manila',
    'Asia/Singapore',
    'Asia/Tokyo',
    'Asia/Hong_Kong',
    'America/Los_Angeles',
    'America/New_York',
    'Europe/London',
    'Europe/Berlin',
    'Australia/Sydney',
    'UTC',
  ];
  final next = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Pick a timezone'),
      children: options
          .map(
            (tz) => SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(tz),
              child: Row(
                children: [
                  if (tz == current)
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.primary,
                    )
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 12),
                  Text(tz),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
  if (next == null || next == current) return;
  await ref
      .read(supabaseServiceProvider)
      .updateUserProfile(userId: userId, timezone: next);
  ref.invalidate(currentUserProvider);
}
