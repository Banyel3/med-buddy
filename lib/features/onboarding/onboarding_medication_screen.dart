import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/router/app_router.dart';
import '../../shared/models/medication_model.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/medication_provider.dart';
import '../../shared/providers/supabase_providers.dart';
import '../../shared/widgets/primary_button.dart';

class OnboardingMedicationScreen extends ConsumerStatefulWidget {
  const OnboardingMedicationScreen({super.key});

  @override
  ConsumerState<OnboardingMedicationScreen> createState() =>
      _OnboardingMedicationScreenState();
}

class _OnboardingMedicationScreenState
    extends ConsumerState<OnboardingMedicationScreen> {
  final _nameCtrl = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 12, minute: 30);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _onContinue() async {
    final user = ref.read(currentSupabaseUserProvider);
    if (user == null) {
      setState(() => _error = 'Sign in first.');
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a medication name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final med = MedicationModel(
        id: '',
        userId: user.id,
        name: name,
        scheduleTime: _time,
        notes: '',
        active: true,
        createdAt: DateTime.now().toUtc(),
      );
      await ref.read(supabaseServiceProvider).createMedication(med);
      // Ask for POST_NOTIFICATIONS here: the user has just picked a reminder
      // time, so the OS prompt lands with obvious context. Android only offers
      // it once. A refusal is not fatal — the app still works, reminders just
      // stay silent until the user grants it in Settings.
      await NotificationService.instance.requestPermissions();
      ref.invalidate(medicationsProvider);
      if (!mounted) return;
      context.goNamed(AppRoute.onboardingMonitor);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Couldn\'t save: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Step 2 of 3'),
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
                  Text(
                    'Set up your medication',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    'You can add more later.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Medication name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Reminder time',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _time.format(context),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Icon(
                            Icons.access_time_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppDimensions.space12),
                    Text(
                      _error!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  ],
                  const Spacer(),
                  PrimaryButton(
                    label: _saving ? 'Saving…' : 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    loading: _saving,
                    onPressed: _saving ? null : _onContinue,
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
