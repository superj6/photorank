import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/arena/arena_screen.dart';
import '../features/beats/moments_screen.dart';
import '../features/bracket/bracket_screen.dart';
import '../features/guest/guest_screen.dart';
import '../features/browse/browse_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/play/play_screen.dart';
import '../features/ranking/photo_detail_screen.dart';
import '../features/ranking/ranking_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/shell_screen.dart';

GoRouter buildRouter({required String initialLocation}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', redirect: (_, _) => initialLocation),
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: '/moments', builder: (_, _) => const MomentsScreen()),
        GoRoute(path: '/bracket', builder: (_, _) => const BracketScreen()),
        GoRoute(path: '/guest', builder: (_, _) => const GuestScreen()),
        GoRoute(
          path: '/photo/:id',
          pageBuilder: (_, state) => CustomTransitionPage(
            child: PhotoDetailScreen(photoId: int.parse(state.pathParameters['id']!)),
            transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => ShellScreen(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/play', builder: (_, _) => const PlayScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/browse', builder: (_, _) => const BrowseScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/ranking', builder: (_, _) => const RankingScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/arena', builder: (_, _) => const ArenaScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen())]),
          ],
        ),
      ],
    );
