import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';

/// Checks a self-hosted version.json (GitHub Pages) and prompts the user to
/// update. Two levels:
///
///   * current < min_version    → BLOCKING dialog (must update)
///   * current < latest_version → friendly, dismissible reminder
///
/// Fails silently when offline — KidWrite is an offline-first app and must
/// never get stuck on a network check.
///
/// To require an update, edit version.json in the GitHub Pages repo
/// (template lives in the project root as version.json).
class UpdateChecker {
  UpdateChecker._();

  static const _configUrl =
      'https://athulsethumadhavan.github.io/KidWrite/version.json';
  static const _appStoreUrl =
      'https://apps.apple.com/in/app/kidwrite/id6781143198';
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.atsIOSDev.kidWrite';

  static bool _checkedThisSession = false;

  static Future<void> check(BuildContext context) async {
    if (_checkedThisSession) return;
    _checkedThisSession = true;

    try {
      final response = await http
          .get(Uri.parse(_configUrl))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return;

      final config = jsonDecode(response.body) as Map<String, dynamic>;
      final minVersion = config['min_version'] as String? ?? '0.0.0';
      final latestVersion =
          config['latest_version'] as String? ?? minVersion;
      final message = config['message'] as String?;

      final info = await PackageInfo.fromPlatform();
      final current = info.version;

      if (!context.mounted) return;

      if (_isOlder(current, minVersion)) {
        _showUpdateDialog(context, force: true, message: message);
      } else if (_isOlder(current, latestVersion)) {
        _showUpdateDialog(context, force: false, message: message);
      }
    } catch (_) {
      // Offline or unreachable — never block the app.
    }
  }

  /// True if version [a] < [b] ("1.2.3" style).
  static bool _isOlder(String a, String b) {
    List<int> parse(String v) => v
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final pa = parse(a), pb = parse(b);
    for (int i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x < y;
    }
    return false;
  }

  static void _showUpdateDialog(
      BuildContext context, {
        required bool force,
        String? message,
      }) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (dialogContext) => PopScope(
        canPop: !force,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Text('🚀', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  force ? 'Update Required' : 'Update Available',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message ??
                (force
                    ? 'This version of KidWrite is no longer supported. '
                    'Please update to keep practicing!'
                    : 'A new version of KidWrite is ready with '
                    'improvements. Update now?'),
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            if (!force)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Later'),
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final url =
                Platform.isIOS ? _appStoreUrl : _playStoreUrl;
                try {
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {}
                // Forced dialog stays open — the app remains unusable
                // until the user actually updates.
                if (!force && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }
}
