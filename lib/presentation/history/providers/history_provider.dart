import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/series.dart';
import '../../../data/providers/data_providers.dart';

class HistoryItem {
  const HistoryItem({
    required this.series,
    required this.chapter,
    required this.progress,
    required this.lastOpenedAt,
  });

  final Series series;
  final Chapter chapter;
  final double progress;
  final DateTime lastOpenedAt;
}

class HistoryGroup {
  const HistoryGroup({
    required this.label,
    required this.items,
  });

  final String label;
  final List<HistoryItem> items;
}

final historyProvider = FutureProvider<List<HistoryGroup>>((ref) async {
  final recentRepo = ref.watch(recentRepositoryProvider);
  final chaptersRepo = ref.watch(chaptersRepositoryProvider);
  final progressRepo = ref.watch(readingProgressRepositoryProvider);

  final recentSeries = await recentRepo.getRecentSeries(limit: 50);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final List<HistoryItem> todayItems = [];
  final List<HistoryItem> yesterdayItems = [];
  final List<HistoryItem> olderItems = [];

  for (final series in recentSeries) {
    final chapters = await chaptersRepo.getChaptersBySeriesId(series.id);
    if (chapters.isEmpty) continue;

    for (final chapter in chapters) {
      final progress = await progressRepo.getProgressByChapterId(chapter.id);
      if (progress == null) continue;

      final item = HistoryItem(
        series: series,
        chapter: chapter,
        progress: chapter.totalPages > 0
            ? progress.currentPage / chapter.totalPages
            : 0.0,
        lastOpenedAt: progress.lastOpenedAt,
      );

      final itemDate = DateTime(
        progress.lastOpenedAt.year,
        progress.lastOpenedAt.month,
        progress.lastOpenedAt.day,
      );

      if (!itemDate.isBefore(today)) {
        todayItems.add(item);
      } else if (!itemDate.isBefore(yesterday)) {
        yesterdayItems.add(item);
      } else {
        olderItems.add(item);
      }
    }
  }

  todayItems.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
  yesterdayItems.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
  olderItems.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));

  final groups = <HistoryGroup>[];
  if (todayItems.isNotEmpty) {
    groups.add(HistoryGroup(label: 'Today', items: todayItems));
  }
  if (yesterdayItems.isNotEmpty) {
    groups.add(HistoryGroup(label: 'Yesterday', items: yesterdayItems));
  }
  if (olderItems.isNotEmpty) {
    groups.add(HistoryGroup(label: 'Older', items: olderItems));
  }

  return groups;
});
