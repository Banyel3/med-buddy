import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';
import 'core/notifications/background_scheduler.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'features/lock/lock_gate.dart';
import 'features/profile/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing — boot with placeholder values so the app still launches in dev.
  }

  await SupabaseBootstrap.init();
  await NotificationService.instance.init();
  await NotificationService.instance.scheduleDailyReminder();
  await BackgroundScheduler.init();

  runApp(const ProviderScope(child: MedBuddyApp()));
}

class MedBuddyApp extends ConsumerWidget {
  const MedBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'MedBuddy',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.lightScheme,
        scaffoldBackgroundColor: AppColors.surface,
        textTheme: AppTextStyles.textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainer,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.outline),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.darkScheme,
        scaffoldBackgroundColor: AppColors.darkSurface,
        textTheme: AppTextStyles.textTheme.apply(
          bodyColor: AppColors.darkOnSurface,
          displayColor: AppColors.darkOnSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkOnSurface,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceContainer,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF55474A)),
          ),
        ),
      ),
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: LockGate(child: child!),
        breakpoints: const [
          Breakpoint(start: 0, end: 599, name: MOBILE),
          Breakpoint(start: 600, end: 1023, name: TABLET),
          Breakpoint(start: 1024, end: double.infinity, name: DESKTOP),
        ],
      ),
    );
  }
}
