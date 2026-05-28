import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ctrl = ref.read(authControllerProvider.notifier);
    try {
      if (_isSignUp) {
        await ctrl.signUp(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        await ctrl.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
      }
      if (!mounted) return;
      context.goNamed(AppRoute.onboardingWelcome);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Auth failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.medical_services_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    Text(
                      _isSignUp ? 'Create account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    Text(
                      _isSignUp
                          ? 'Set up your MedBuddy account'
                          : 'Sign in to keep your streak',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppDimensions.space32),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter email'
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: AppDimensions.space24),
                    PrimaryButton(
                      label: _isSignUp ? 'Create account' : 'Sign in',
                      loading: auth.isLoading,
                      onPressed: auth.isLoading ? null : _submit,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? 'Have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
