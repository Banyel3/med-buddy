import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/models/medication_model.dart';
import '../../shared/providers/medication_provider.dart';
import '../../shared/providers/supabase_providers.dart';
import '../../shared/widgets/primary_button.dart';

/// Edit screen for a single medication. Pass the [medication] via
/// GoRouter `extra` to edit; pass null to create.
class MedicationEditScreen extends ConsumerStatefulWidget {
  final MedicationModel? medication;

  const MedicationEditScreen({super.key, this.medication});

  @override
  ConsumerState<MedicationEditScreen> createState() =>
      _MedicationEditScreenState();
}

class _MedicationEditScreenState extends ConsumerState<MedicationEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  late TimeOfDay _time;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.medication != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.medication?.name ?? '');
    _notesCtrl =
        TextEditingController(text: widget.medication?.notes ?? '');
    _time = widget.medication?.scheduleTime ??
        const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a medication name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final svc = ref.read(supabaseServiceProvider);
      final notes = _notesCtrl.text.trim();
      if (_isEdit) {
        final updated = MedicationModel(
          id: widget.medication!.id,
          userId: widget.medication!.userId,
          name: name,
          scheduleTime: _time,
          notes: notes,
          active: widget.medication!.active,
          createdAt: widget.medication!.createdAt,
        );
        await svc.updateMedication(updated);
      } else {
        // create path uses onboarding flow; keep a path here for completeness
        throw StateError('Use onboarding to create the first medication.');
      }
      ref.invalidate(medicationsProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Couldn\'t save: $e';
      });
    }
  }

  Future<void> _delete() async {
    final med = widget.medication;
    if (med == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove medication?'),
        content: Text(
            '${med.name} will stop appearing on Home. Past doses stay in your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(supabaseServiceProvider).deleteMedication(med.id);
      ref.invalidate(medicationsProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Couldn\'t remove: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(_isEdit ? 'Edit medication' : 'New medication'),
        elevation: 0,
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              onPressed: _busy ? null : _delete,
              tooltip: 'Remove',
            ),
        ],
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
                  TextField(
                    controller: _notesCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppDimensions.space12),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ],
                  const Spacer(),
                  PrimaryButton(
                    label: _busy ? 'Saving…' : 'Save',
                    icon: Icons.check_rounded,
                    loading: _busy,
                    onPressed: _busy ? null : _save,
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
