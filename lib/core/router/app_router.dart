import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/lock/lock_screen.dart';
import '../../features/onboarding/onboarding_medication_screen.dart';
import '../../features/onboarding/onboarding_monitor_screen.dart';
import '../../features/onboarding/onboarding_welcome_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/verification/verification_screen.dart';
import '../../shared/widgets/medbuddy_scaffold.dart';

class AppRoute {
  static const splash = 'splash';
  static const login = 'login';
  static const onboardingWelcome = 'onboardingWelcome';
  static const onboardingMedication = 'onboardingMedication';
  static const onboardingMonitor = 'onboardingMonitor';
  static const home = 'home';
  static const history = 'history';
  static const profile = 'profile';
  static const verification = 'verification';
  static const lock = 'lock';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        name: AppRoute.splash,
        path: '/splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        name: AppRoute.login,
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        name: AppRoute.onboardingWelcome,
        path: '/onboarding/welcome',
        builder: (_, _) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        name: AppRoute.onboardingMedication,
        path: '/onboarding/medication',
        builder: (_, _) => const OnboardingMedicationScreen(),
      ),
      GoRoute(
        name: AppRoute.onboardingMonitor,
        path: '/onboarding/monitor',
        builder: (_, _) => const OnboardingMonitorScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MedBuddyScaffold(location: state.uri.toString(), child: child),
        routes: [
          GoRoute(
            name: AppRoute.home,
            path: '/home',
            pageBuilder: (_, _) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            name: AppRoute.history,
            path: '/history',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            name: AppRoute.profile,
            path: '/profile',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: _ProfilePlaceholder()),
          ),
        ],
      ),
      GoRoute(
        name: AppRoute.verification,
        path: '/verification',
        builder: (_, _) => const VerificationScreen(),
      ),
      GoRoute(
        name: AppRoute.lock,
        path: '/lock',
        builder: (_, _) => const LockScreen(),
      ),
    ],
  );
});

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Profile (coming soon)'));
}
