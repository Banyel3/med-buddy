import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'features/lock/alarm_outcome_sync.dart';
import 'features/lock/alarm_settings_provider.dart';
import 'features/lock/lock_gate.dart';
import 'features/profile/theme_provider.dart';
import 'shared/providers/lock_provider.dart';
import 'shared/providers/medication_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing — boot with placeholder values so the app still launches in dev.
  }

  await SupabaseBootstrap.init();
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: MedBuddyApp()));
}

class MedBuddyApp extends ConsumerStatefulWidget {
  const MedBuddyApp({super.key});

  @override
  ConsumerState<MedBuddyApp> createState() => _MedBuddyAppState();
}

class _MedBuddyAppState extends ConsumerState<MedBuddyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A dose alarm may already be ringing when the app is opened from the
    // overlay's "Verify now" or the full-screen notification.
    ref.read(lockServiceProvider).syncLockState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(lockServiceProvider).syncLockState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Instantiate eagerly: the controller pushes MEDBUDDY_ALARM (build flag /
    // .env) into native SharedPreferences. Before this it was only created
    // when Profile was opened, so lock alarms were armed with the pin unset.
    ref.watch(alarmEnabledProvider);

    // Re-schedule local reminders whenever the medication list changes
    // (boot, after create/edit/delete). Keeps notification IDs in sync with
    // real medication.id.hashCode values so updates replace, don't stack.
    ref.listen(medicationsProvider, (_, next) {
      final meds = next.valueOrNull;
      if (meds == null) return;
      NotificationService.instance.scheduleAllReminders(meds);
      // An alarm may have ended (skipped, or hit its ceiling) while no Flutter
      // engine was alive. Drain those into compliance_logs now that we have a
      // signed-in user and a live connection.
      ref.read(alarmOutcomeSyncProvider).drainAndLog();
    });
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
            borderSide: BorderSide(color: Color(0xFF6B4D58)),
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
