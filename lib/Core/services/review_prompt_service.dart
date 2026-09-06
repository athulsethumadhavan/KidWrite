import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Constants/app_colors.dart';
import '../Constants/app_constants.dart';

/// Asks the parent for a review once the child has finished a few letters —
/// and only if they haven't reviewed (or opted out) already.
///
/// Flow:
///   1. A letter reaches 3 stars → [registerLevelCompleted].
///   2. After [AppConstants.reviewFirstPromptAfter] levels we show a
///      friendly "Are you enjoying KidWrite?" sheet.
///   3. 😍  → native store review prompt, never asked again.
///      🙁  → feedback email, never asked again (we'd rather fix things
///            than collect a bad rating).
///      Later → asked again after a few more levels.
class ReviewPromptService {
  ReviewPromptService._();

  static const _appStoreUrl =
      'https://apps.apple.com/in/app/kidwrite/id6781143198';
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.atsIOSDev.kidWrite';
  static const _appStoreId = '6781143198';

  /// Records one completed level and returns true if the review prompt
  /// should now be shown.
  static Future<bool> registerLevelCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppConstants.prefReviewDone) ?? false) return false;

    final levels = (prefs.getInt(AppConstants.prefLevelsCompleted) ?? 0) + 1;
    await prefs.setInt(AppConstants.prefLevelsCompleted, levels);

    final nextAt =
        prefs.getInt(AppConstants.prefReviewNextAt) ??
        AppConstants.reviewFirstPromptAfter;
    return levels >= nextAt;
  }

  static Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefReviewDone, true);
  }

  /// Called when the parent rates from the settings menu — we then never
  /// ask again automatically.
  static Future<void> markReviewedManually() => _markDone();

  static Future<void> _snooze() async {
    final prefs = await SharedPreferences.getInstance();
    final levels = prefs.getInt(AppConstants.prefLevelsCompleted) ?? 0;
    await prefs.setInt(
      AppConstants.prefReviewNextAt,
      levels + AppConstants.reviewSnoozeLevels,
    );
  }

  /// Shows the review / feedback sheet.
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _ReviewSheet(
        onLove: () async {
          Navigator.pop(sheetContext);
          await _markDone();
          try {
            final review = InAppReview.instance;
            if (await review.isAvailable()) {
              await review.requestReview();
            } else {
              await review.openStoreListing(appStoreId: _appStoreId);
            }
          } catch (_) {
            // Fall back to the plain store link.
            try {
              await launchUrl(
                Uri.parse(Platform.isIOS ? _appStoreUrl : _playStoreUrl),
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {}
          }
        },
        onFeedback: () async {
          Navigator.pop(sheetContext);
          await _markDone();
          final uri = Uri(
            scheme: 'mailto',
            path: AppConstants.supportEmail,
            query:
                'subject=KidWrite Feedback'
                '&body=Hi! Here is what could be better in KidWrite:\n\n',
          );
          try {
            await launchUrl(uri);
          } catch (_) {}
        },
        onLater: () async {
          Navigator.pop(sheetContext);
          await _snooze();
        },
      ),
    );
  }
}

class _ReviewSheet extends StatelessWidget {
  final Future<void> Function() onLove;
  final Future<void> Function() onFeedback;
  final Future<void> Function() onLater;

  const _ReviewSheet({
    required this.onLove,
    required this.onFeedback,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
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
            const SizedBox(height: 20),
            const Text('⭐️', style: TextStyle(fontSize: 46)),
            const SizedBox(height: 10),
            const Text(
              'Enjoying KidWrite?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your little one is doing great! A quick review helps other '
              'parents find KidWrite.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _ChoiceButton(
                    emoji: '🙁',
                    label: 'Could be better',
                    color: AppColors.orange,
                    filled: false,
                    onTap: onFeedback,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ChoiceButton(
                    emoji: '😍',
                    label: 'Love it!',
                    color: AppColors.primary,
                    filled: true,
                    onTap: onLove,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: onLater,
              child: const Text(
                'Maybe later',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
