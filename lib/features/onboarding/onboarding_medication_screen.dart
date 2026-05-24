import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/primary_button.dart';

class OnboardingMedicationScreen extends StatefulWidget {
  const OnboardingMedicationScreen({super.key});

  @override
  State<OnboardingMedicationScreen> createState() =>
      _OnboardingMedicationScreenState();
}

class _OnboardingMedicationScreenState
    extends State<OnboardingMedicationScreen> {
  final _nameCtrl = TextEditingController(text: 'Iron + Creatine');
  TimeOfDay _time = const TimeOfDay(hour: 12, minute: 30);
  String _frequency = 'Daily';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
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
                  Text('Set up your medication',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: AppDimensions.space8),
                  Text('You can add more later.',
                      style: Theme.of(context).textTheme.bodyMedium),
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
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Reminder time',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_time.format(context),
                              style: Theme.of(context).textTheme.titleMedium),
                          const Icon(Icons.access_time_rounded,
                              color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  DropdownButtonFormField<String>(
                    initialValue: _frequency,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                      DropdownMenuItem(
                          value: 'Weekdays', child: Text('Weekdays')),
                      DropdownMenuItem(
                          value: 'Custom', child: Text('Custom')),
                    ],
                    onChanged: (v) =>
                        setState(() => _frequency = v ?? 'Daily'),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () =>
                        context.goNamed(AppRoute.onboardingMonitor),
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
