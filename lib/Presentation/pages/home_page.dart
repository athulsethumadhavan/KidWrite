import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/widgets/animated_background.dart';
import '../../domain/entities/language.dart';
import '../../injection_container.dart';
import '../blocs/home/home_bloc.dart';
import '../blocs/music/music_bloc.dart';
import '../widgets/language_card.dart';
import '../widgets/music_toggle_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeBloc>()..add(const HomeLoadLanguages()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      body: AnimatedBackground(
        primaryColor: AppColors.primary,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello! 👋',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            'What do you want\nto practice today?',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    BlocBuilder<MusicBloc, MusicState>(
                      bloc: sl<MusicBloc>(),
                      builder: (_, state) => MusicToggleButton(
                        isEnabled: state.isMusicEnabled,
                        onTap: () => sl<MusicBloc>().add(const MusicToggle()),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
              ),

              const SizedBox(height: 16),

              // Language grid
              Expanded(
                child: BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    if (state is HomeLoading) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (state is HomeLoaded) {
                      return _LanguageGrid(
                        languages: state.languages,
                        isTablet: isTablet,
                      );
                    }
                    if (state is HomeError) {
                      return Center(child: Text(state.message));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageGrid extends StatelessWidget {
  final List<Language> languages;
  final bool isTablet;

  const _LanguageGrid({required this.languages, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isTablet ? 3 : 2;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isTablet ? 1.2 : 1.0,
      ),
      itemCount: languages.length,
      itemBuilder: (context, index) {
        final lang = languages[index];
        return LanguageCard(
          language: lang,
          onTap: () => context.push('/characters/${lang.id}'),
        )
            .animate(delay: (index * 80).ms)
            .fadeIn(duration: 400.ms)
            .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
      },
    );
  }
}
