import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/chapter.dart';
import '../../domain/entities/series.dart';
import '../../presentation/history/pages/history_page.dart';
import '../../presentation/home/pages/home_page.dart';
import '../../presentation/onboarding/pages/onboarding_page.dart';
import '../../presentation/reader/pages/reader_page.dart';
import '../../presentation/series_detail/pages/series_detail_page.dart';
import '../../presentation/settings/pages/settings_page.dart';
import '../../presentation/splash/pages/splash_page.dart';
import '../../presentation/thumbnails/pages/thumbnail_viewer_page.dart';

class ThumbnailViewerArgs {
  const ThumbnailViewerArgs({
    required this.chapter,
    required this.totalPages,
    this.currentPage = 0,
  });

  final Chapter chapter;
  final int totalPages;
  final int currentPage;
}

/// Custom page transition — fade
CustomTransitionPage<void> _fadeTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
  );
}

/// Slide-up transition for bottom sheets and modals
CustomTransitionPage<void> _slideUpTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => _fadeTransition(
          context,
          state,
          const SplashPage(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _fadeTransition(
          context,
          state,
          const OnboardingPage(),
        ),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => _fadeTransition(
          context,
          state,
          const HomePage(),
        ),
      ),
      GoRoute(
        path: '/series',
        name: 'series_detail',
        pageBuilder: (context, state) {
          final series = state.extra as Series;
          return _slideUpTransition(
            context,
            state,
            SeriesDetailPage(series: series),
          );
        },
      ),
      GoRoute(
        path: '/reader',
        name: 'reader',
        pageBuilder: (context, state) {
          final chapter = state.extra as Chapter;
          return _fadeTransition(
            context,
            state,
            ReaderPage(chapter: chapter),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _slideUpTransition(
          context,
          state,
          const SettingsPage(),
        ),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        pageBuilder: (context, state) => _fadeTransition(
          context,
          state,
          const HistoryPage(),
        ),
      ),
      GoRoute(
        path: '/thumbnails',
        name: 'thumbnails',
        pageBuilder: (context, state) {
          final args = state.extra as ThumbnailViewerArgs;
          return _slideUpTransition(
            context,
            state,
            ThumbnailViewerPage(
              chapter: args.chapter,
              totalPages: args.totalPages,
              currentPage: args.currentPage,
            ),
          );
        },
      ),
    ],
  );
});
