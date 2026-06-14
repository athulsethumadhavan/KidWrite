import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/character.dart';
import '../../Presentation/pages/character_list_page.dart';
import '../../Presentation/pages/home_page.dart';
import '../../Presentation/pages/splash_page.dart';
import '../../Presentation/pages/writing_practice_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashPage(),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (_, state) => _slidePage(state, const HomePage()),
    ),
    GoRoute(
      path: '/characters/:languageId',
      pageBuilder: (_, state) => _slidePage(
        state,
        CharacterListPage(
          languageId: state.pathParameters['languageId']!,
        ),
      ),
    ),
    GoRoute(
      path: '/practice/:languageId/:characterId',
      pageBuilder: (context, state) {
        final character = state.extra as Character;
        return _slidePage(
          state,
          WritingPracticePage(
            languageId: state.pathParameters['languageId']!,
            character: character,
          ),
        );
      },
    ),
  ],
);

CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, childWidget) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
        ),
        child: childWidget,
      );
    },
  );
}
