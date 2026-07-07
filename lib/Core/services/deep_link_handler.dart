import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

/// Routes incoming `kidwrite://` links (custom-scheme deep links, e.g. from
/// App Store Connect in-app events) to the matching in-app destination.
class DeepLinkHandler {
  DeepLinkHandler._();

  static final _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;

  static Future<void> init(GoRouter router) async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handle(initialUri, router);
    }

    _subscription = _appLinks.uriLinkStream.listen((uri) => _handle(uri, router));
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  static void _handle(Uri uri, GoRouter router) {
    // kidwrite://event/back-to-school -> Home page (language selection)
    if (uri.host == 'event') {
      router.go('/home');
    }
  }
}
