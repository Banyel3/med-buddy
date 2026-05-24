import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const _entries = [
    _Credit(
      title: 'YOLOv8 pill detection model',
      author: 'seblful',
      license: 'CC BY 4.0',
      url: 'https://github.com/seblful/pills-detection',
    ),
    _Credit(
      title: 'MediaPipe / Google ML Kit Face Detection',
      author: 'Google',
      license: 'Apache 2.0',
      url: 'https://developers.google.com/ml-kit',
    ),
    _Credit(
      title: 'Plus Jakarta Sans + Be Vietnam Pro fonts',
      author: 'Google Fonts',
      license: 'OFL 1.1',
      url: 'https://fonts.google.com',
    ),
    _Credit(
      title: 'Flutter SDK',
      author: 'Google',
      license: 'BSD-3-Clause',
      url: 'https://flutter.dev',
    ),
    _Credit(
      title: 'Supabase Flutter / SSR',
      author: 'Supabase',
      license: 'MIT',
      url: 'https://supabase.com',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credits & licenses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space24),
          children: [
            Text(
              'MedBuddy stands on the shoulders of open-source software '
              'and freely-licensed research.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.space24),
            for (final c in _entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.space16),
                child: _CreditCard(credit: c),
              ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              'See LICENSE files in the source repository for full terms.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Credit {
  final String title;
  final String author;
  final String license;
  final String url;
  const _Credit({
    required this.title,
    required this.author,
    required this.license,
    required this.url,
  });
}

class _CreditCard extends StatelessWidget {
  final _Credit credit;
  const _CreditCard({required this.credit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(credit.title,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('by ${credit.author} — ${credit.license}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(credit.url,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  )),
        ],
      ),
    );
  }
}
