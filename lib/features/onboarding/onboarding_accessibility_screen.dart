import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../shared/providers/lock_provider.dart';
import '../../shared/widgets/primary_button.dart';

class OnboardingAccessibilityScreen extends ConsumerStatefulWidget {
  const OnboardingAccessibilityScreen({super.key});

  @override
  ConsumerState<OnboardingAccessibilityScreen> createState() =>
      _OnboardingAccessibilityScreenState();
}

class _OnboardingAccessibilityScreenState
    extends ConsumerState<OnboardingAccessibilityScreen>
    with WidgetsBindingObserver {
  bool _enabled = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final ok =
        await ref.read(lockServiceProvider).isAccessibilityEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = ok;
      _checking = false;
    });
  }

  Future<void> _openSettings() async {
    await ref.read(lockServiceProvider).openAccessibilitySettings();
  }

  Future<void> _requestOverlay() async {
    await ref.read(lockServiceProvider).requestOverlayPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Almost done'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Enable lock mode (optional)',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    'MedBuddy can lock your phone when you skip a dose. '
                    'Grant Accessibility + overlay permission to enable. '
                    'You can skip and turn it on later.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  _PermRow(
                    title: 'Accessibility service',
                    granted: _enabled,
                    busy: _checking,
                    onTap: _openSettings,
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  _PermRow(
                    title: 'Display over other apps',
                    granted: false,
                    onTap: _requestOverlay,
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: _enabled
                        ? 'All set — finish'
                        : 'Continue without lock',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.goNamed(AppRoute.home),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final String title;
  final bool granted;
  final bool busy;
  final VoidCallback onTap;

  const _PermRow({
    required this.title,
    required this.granted,
    this.busy = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: granted ? AppColors.secondary : AppColors.outline,
            width: granted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              granted
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: granted ? AppColors.secondary : AppColors.primary,
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                granted ? 'Granted' : 'Tap to open',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: granted
                          ? AppColors.secondary
                          : AppColors.onSurface.withValues(alpha: 0.6),
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
