import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/device_utils.dart';
import '../../shared/widgets/primary_button.dart';

/// Phase 3 lock screen. Rendered when MedBuddy is brought to front by the
/// accessibility service. Blocks BACK at the Flutter layer (the Android
/// service additionally re-asserts overlay if user escapes) and presents
/// a single CTA to start verification.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  late final DateTime _start;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(_start));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = DeviceUtils.isTablet(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop(animated: false);
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.coralGradient),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 520 : 480),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.space24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.medication_liquid_rounded,
                        size: 128,
                        color: AppColors.onPrimary,
                      ),
                      const SizedBox(height: AppDimensions.space24),
                      Text(
                        "Hey! Don't forget your meds today 💊",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppColors.onPrimary),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Text(
                        'Pop in for a quick verify — takes 30 seconds.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        child: Text(
                          'Locked for ${_fmt(_elapsed)}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.onPrimary),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space40),
                      PrimaryButton(
                        label: 'Take it now',
                        icon: Icons.camera_alt_rounded,
                        gradient: false,
                        onPressed: () => context.goNamed(AppRoute.verification),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
