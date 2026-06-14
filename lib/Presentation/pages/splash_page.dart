import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_background.dart';
import '../../injection_container.dart';
import '../blocs/music/music_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    sl<MusicBloc>().add(const MusicInitialize());
    Future.delayed(AppConstants.splashDuration, () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AnimatedBackground(
        primaryColor: AppColors.primary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon / mascot
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '✏️',
                    style: TextStyle(fontSize: 72),
                  ),
                ),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              Text(
                AppConstants.appName,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: AppColors.primary,
                  letterSpacing: -1,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 12),

              Text(
                'Learn to write — letters, numbers & more!',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 500.ms),

              const SizedBox(height: 60),

              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              )
                  .animate()
                  .fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
