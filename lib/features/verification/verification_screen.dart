import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Phase 1 placeholder. Phase 2 wires camera + MediaPipe face + YOLOv8 pill.
class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.onPrimary,
        title: const Text('Verify your dose'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_rounded,
                  size: 96, color: AppColors.onPrimary),
              const SizedBox(height: AppDimensions.space16),
              Text(
                'Verification flow (Phase 2)',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.onPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                'Camera, MediaPipe face detection, and YOLOv8 pill detection wire up here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.75),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.space32),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
