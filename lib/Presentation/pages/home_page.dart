import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';
import 'package:kid_write/Core/services/update_checker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/widgets/animated_background.dart';
import '../../domain/entities/language.dart';
import '../../injection_container.dart';
import '../blocs/home/home_bloc.dart';
import '../blocs/music/music_bloc.dart';
import '../widgets/language_card.dart';
import '../widgets/music_toggle_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Force-update check (reads version.json from GitHub Pages).
    // Runs once per app session; fails silently offline.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) UpdateChecker.check(context);
    });
  }

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

  static const _supportEmail = 'atsdigiservice@gmail.com+kidwrite@gmail.com';
  static const _privacyPolicyUrl =
      'https://athulsethumadhavan.github.io/KidWrite/privacy_policy.html';
  static const _appStoreId = '6781143198';
  // Store pages:
  //   https://apps.apple.com/in/app/kidwrite/id6781143198
  //   https://play.google.com/store/apps/details?id=com.atsIOSDev.kidWrite

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 14),
              _SettingsTile(
                icon: Icons.star_rate_rounded,
                iconColor: const Color(0xFFFFB300),
                title: 'Rate KidWrite',
                subtitle: 'Enjoying the app? Leave us a rating!',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final review = InAppReview.instance;
                  try {
                    if (await review.isAvailable()) {
                      await review.requestReview();
                    } else {
                      await review.openStoreListing(
                          appStoreId: _appStoreId);
                    }
                  } catch (_) {}
                },
              ),
              _SettingsTile(
                icon: Icons.support_agent_rounded,
                iconColor: AppColors.secondary,
                title: 'Help & Support',
                subtitle: _supportEmail,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final uri = Uri(
                    scheme: 'mailto',
                    path: _supportEmail,
                    query: 'subject=KidWrite Support',
                  );
                  try {
                    await launchUrl(uri);
                  } catch (_) {}
                },
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_rounded,
                iconColor: AppColors.green,
                title: 'Privacy Policy',
                subtitle: 'Child-safe: no data ever leaves your device',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  // Open the hosted policy; fall back to the in-app
                  // summary if the browser can't be launched.
                  var opened = false;
                  try {
                    opened = await launchUrl(
                      Uri.parse(_privacyPolicyUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {}
                  if (!opened && context.mounted) {
                    _showPrivacyPolicy(context);
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.info_rounded,
                iconColor: AppColors.purple,
                title: 'About',
                subtitle:
                'KidWrite v${AppConstants.appVersion}',
                onTap: () {
                  Navigator.pop(sheetContext);
                  showAboutDialog(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: AppConstants.appVersion,
                    applicationIcon: const Text(
                      '✏️',
                      style: TextStyle(fontSize: 40),
                    ),
                    children: const [
                      Text(
                        'A fun tracing app that helps children below 6 '
                            'learn to write letters and numbers in English, '
                            'Malayalam, Hindi and Tamil.\n\n'
                            'Made with ❤️ for little writers.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('🔒 Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            'KidWrite is a child-safe writing practice app for children '
                'under 6.\n\n'
                'WHAT WE COLLECT\n'
                'Nothing. KidWrite does not collect, transmit or share any '
                'personal information. The app works completely offline. We '
                'never collect names, contact details, device identifiers, '
                'location, photos, microphone input, or analytics.\n\n'
                'DATA ON YOUR DEVICE\n'
                'Only writing progress is stored (letters practiced, '
                'accuracy scores, music preference), using your device\'s '
                'standard local storage. It never leaves the device. '
                'Uninstalling the app permanently deletes it.\n\n'
                'INTERNET\n'
                'KidWrite does not require an internet connection and shows '
                'no ads.\n\n'
                'CONTACT\n'
                'Questions? Email $_supportEmail',
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 8),
                child: Row(
                  // Icons pin to the TOP so they sit beside the greeting
                  // line instead of floating next to the tall title.
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(height: 2),
                          // FittedBox scales the text down if space is
                          // tight, so the title is ALWAYS exactly 2 lines.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'What do you want\nto practice today?',
                              style:
                              theme.textTheme.headlineLarge?.copyWith(
                                color: AppColors.textDark,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    BlocBuilder<MusicBloc, MusicState>(
                      bloc: sl<MusicBloc>(),
                      builder: (_, state) => MusicToggleButton(
                        isEnabled: state.isMusicEnabled,
                        onTap: () => sl<MusicBloc>().add(const MusicToggle()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Settings: rating / support / privacy / about
                    GestureDetector(
                      onTap: () => _showSettingsSheet(context),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 26),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12.5, color: AppColors.textLight),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textLight,
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
