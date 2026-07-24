import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/chapter.dart';
import '../../domain/entities/series.dart';
import '../../presentation/home/pages/home_page.dart';
import '../../presentation/reader/pages/reader_page.dart';
import '../../presentation/series_detail/pages/series_detail_page.dart';
import '../../presentation/settings/pages/settings_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/series',
        name: 'series_detail',
        builder: (context, state) {
          final series = state.extra as Series;
          return SeriesDetailPage(series: series);
        },
      ),
      GoRoute(
        path: '/reader',
        name: 'reader',
        builder: (context, state) {
          final chapter = state.extra as Chapter;
          return ReaderPage(chapter: chapter);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
