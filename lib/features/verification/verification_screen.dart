import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/primary_button.dart';
import 'controllers/verification_controller.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  Future<void>? _init;
  bool _permGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _permGranted = false);
      return;
    }
    setState(() => _permGranted = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _init = controller.initialize();
      await _init;
      if (!mounted) return;
      setState(() => _camera = controller);
    } catch (e) {
      debugPrint('Camera init failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    final c = _camera;
    if (s == AppLifecycleState.inactive) {
      if (c?.value.isInitialized ?? false) c!.pausePreview();
    } else if (s == AppLifecycleState.resumed) {
      if (c == null || !c.value.isInitialized) {
        _bootstrap();
      } else {
        c.resumePreview();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final c = _camera;
    if (c == null || !c.value.isInitialized) return;
    try {
      final file = await c.takePicture();
      await ref
          .read(verificationControllerProvider.notifier)
          .analyzeCapture(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e')),
      );
    }
  }

  Future<void> _confirm() async {
    final ok = await ref
        .read(verificationControllerProvider.notifier)
        .confirmDose();
    if (!mounted) return;
    if (ok) {
      context.goNamed(AppRoute.home);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dose verified ✅ streak updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save — retry or check connection')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationControllerProvider);
    if (!_permGranted) {
      return _PermissionDenied(onRetry: _bootstrap);
    }
    final c = _camera;
    if (c == null || !c.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.onPrimary)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(c),
            const _GuideOverlay(),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(onClose: () => context.pop()),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomPanel(
                state: state,
                onCapture: _capture,
                onConfirm: _confirm,
                onRetake: () => ref
                    .read(verificationControllerProvider.notifier)
                    .resetForRetake(),
                lastImage: state.lastResult?.capturedPath,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.onPrimary),
            onPressed: onClose,
          ),
          const SizedBox(width: 4),
          Text(
            'Verify your dose',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _GuideOverlay extends StatelessWidget {
  const _GuideOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Face guide oval.
            Container(
              width: 240,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.onPrimary.withValues(alpha: 0.6),
                    width: 3),
                borderRadius: BorderRadius.circular(160),
              ),
            ),
            const SizedBox(height: 16),
            // Pill guide box.
            Container(
              width: 110,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.onPrimary.withValues(alpha: 0.6),
                    width: 2),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Center(
                child: Text(
                  'Pill',
                  style: TextStyle(
                    color: AppColors.onPrimary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final VerificationState state;
  final VoidCallback onCapture;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;
  final String? lastImage;

  const _BottomPanel({
    required this.state,
    required this.onCapture,
    required this.onConfirm,
    required this.onRetake,
    required this.lastImage,
  });

  @override
  Widget build(BuildContext context) {
    final result = state.lastResult;
    final analyzing = state.analyzing;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result != null) ...[
            Row(
              children: [
                Expanded(
                  child: _ConfidenceBar(
                    label: 'Face',
                    value: result.faceConfidence,
                    threshold: VerificationResult.faceThreshold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ConfidenceBar(
                    label: 'Pill',
                    value: result.pillConfidence,
                    threshold: VerificationResult.pillThreshold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (result.passed)
              const _Hint(
                  icon: Icons.check_circle_rounded,
                  color: AppColors.secondary,
                  text: 'Looks great! Confirm to log this dose.')
            else
              const _Hint(
                icon: Icons.refresh_rounded,
                color: AppColors.warning,
                text: 'Hold your pill up clearly and smile 😊 — try again.',
              ),
            const SizedBox(height: 16),
          ],
          if (analyzing) ...[
            const LinearProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 12),
            Text('Analyzing…',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.onPrimary)),
          ] else if (result == null) ...[
            PrimaryButton(
              label: 'Capture',
              icon: Icons.camera_alt_rounded,
              onPressed: onCapture,
            ),
          ] else if (result.passed) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onPrimary,
                      side: const BorderSide(color: AppColors.onPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: onRetake,
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'Confirm & log',
                    icon: Icons.check_rounded,
                    loading: state.submitting,
                    onPressed: state.submitting ? null : onConfirm,
                  ),
                ),
              ],
            ),
          ] else ...[
            PrimaryButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              onPressed: onRetake,
            ),
          ],
          if (lastImage != null && result == null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: SizedBox(
                height: 60,
                width: 60,
                child: Image.file(File(lastImage!), fit: BoxFit.cover),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final String label;
  final double value;
  final double threshold;
  const _ConfidenceBar({
    required this.label,
    required this.value,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    final pass = value >= threshold;
    final color = pass ? AppColors.secondary : AppColors.warning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.onPrimary)),
            const Spacer(),
            Text('${(value * 100).toStringAsFixed(0)}%',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Hint({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onPrimary)),
        ),
      ],
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionDenied({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_photography_rounded,
                    color: AppColors.onPrimary, size: 72),
                const SizedBox(height: 16),
                Text(
                  'Camera permission needed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.onPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'MedBuddy uses the camera to verify your dose. Grant access to continue.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.75),
                      ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Open settings',
                  icon: Icons.settings_rounded,
                  onPressed: () => openAppSettings(),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Retry',
                      style: TextStyle(color: AppColors.onPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

