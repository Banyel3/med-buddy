import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../shared/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final user = ref.read(currentSupabaseUserProvider);
    if (user == null) {
      context.goNamed(AppRoute.login);
    } else {
      context.goNamed(AppRoute.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_rounded,
              color: AppColors.onPrimary,
              size: 72,
            ),
            SizedBox(height: 12),
            Text(
              'MedBuddy',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
