import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/chapter.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/entities/series.dart';
import '../../domain/entities/thumbnail.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../../domain/repositories/chapters_repository.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../../domain/repositories/recent_repository.dart';
import '../../domain/repositories/series_repository.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../../infrastructure/services/file_watcher_service.dart';
import '../../infrastructure/services/library_scanner.dart';
import '../../infrastructure/services/thumbnail_service.dart';
import '../repositories/bookmark_repository_impl.dart';
import '../repositories/chapters_repository_impl.dart';
import '../repositories/favorites_repository_impl.dart';
import '../repositories/reading_progress_repository_impl.dart';
import '../repositories/recent_repository_impl.dart';
import '../repositories/series_repository_impl.dart';
import '../repositories/thumbnail_repository_impl.dart';

final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  return SeriesRepositoryImpl();
});

final chaptersRepositoryProvider = Provider<ChaptersRepository>((ref) {
  return ChaptersRepositoryImpl();
});

final readingProgressRepositoryProvider = Provider<ReadingProgressRepository>((ref) {
  return ReadingProgressRepositoryImpl();
});

final thumbnailRepositoryProvider = Provider<ThumbnailRepository>((ref) {
  return ThumbnailRepositoryImpl();
});

final thumbnailServiceProvider = Provider<ThumbnailService>((ref) {
  final repo = ref.watch(thumbnailRepositoryProvider);
  return ThumbnailService(repo);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl();
});

final recentRepositoryProvider = Provider<RecentRepository>((ref) {
  return RecentRepositoryImpl();
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepositoryImpl();
});

final libraryScannerProvider = Provider<LibraryScanner>((ref) {
  final seriesRepo = ref.watch(seriesRepositoryProvider);
  final chaptersRepo = ref.watch(chaptersRepositoryProvider);
  return LibraryScanner(seriesRepo, chaptersRepo);
});

final fileWatcherServiceProvider = Provider<FileWatcherService>((ref) {
  final seriesRepo = ref.watch(seriesRepositoryProvider);
  final chaptersRepo = ref.watch(chaptersRepositoryProvider);
  return FileWatcherService(seriesRepo, chaptersRepo);
});

final allSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final repo = ref.watch(seriesRepositoryProvider);
  return repo.getVisibleSeries();
});

final chaptersBySeriesProvider =
    FutureProvider.family<List<Chapter>, int>((ref, seriesId) async {
  final repo = ref.watch(chaptersRepositoryProvider);
  return repo.getChaptersBySeriesId(seriesId);
});

final recentProgressProvider = FutureProvider<List<ReadingProgress>>((ref) async {
  final repo = ref.watch(readingProgressRepositoryProvider);
  return repo.getRecentProgress(limit: 10);
});

final progressByChapterProvider =
    FutureProvider.family<ReadingProgress?, int>((ref, chapterId) async {
  final repo = ref.watch(readingProgressRepositoryProvider);
  return repo.getProgressByChapterId(chapterId);
});

final thumbnailBySeriesProvider =
    FutureProvider.family<Thumbnail?, int>((ref, seriesId) async {
  final service = ref.watch(thumbnailServiceProvider);
  final seriesRepo = ref.watch(seriesRepositoryProvider);
  final series = await seriesRepo.getSeriesById(seriesId);
  if (series == null) return null;
  return service.getThumbnail(seriesId, series.path);
});

final favoriteSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.getFavoriteSeries();
});

final isFavoriteProvider =
    FutureProvider.family<bool, int>((ref, seriesId) async {
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.isFavorite(seriesId);
});

final recentSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final repo = ref.watch(recentRepositoryProvider);
  return repo.getRecentSeries(limit: 10);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Series>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return [];
  }
  final repo = ref.watch(seriesRepositoryProvider);
  final allSeries = await repo.getAllSeries();
  final lowerQuery = query.toLowerCase();
  return allSeries
      .where((s) => s.name.toLowerCase().contains(lowerQuery))
      .toList();
});

class ScanNotifier extends StateNotifier<AsyncValue<ScanResult?>> {
  ScanNotifier(this._scanner) : super(const AsyncData(null));

  final LibraryScanner _scanner;

  Future<void> scanFolder(String folderPath) async {
    state = const AsyncLoading();
    try {
      final result = await _scanner.scanFolder(folderPath);
      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final scanNotifierProvider =
    StateNotifierProvider<ScanNotifier, AsyncValue<ScanResult?>>((ref) {
  final scanner = ref.watch(libraryScannerProvider);
  return ScanNotifier(scanner);
});

final vaultedSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final repo = ref.watch(seriesRepositoryProvider);
  return repo.getVaultedSeries();
});

final isVaultedProvider =
    FutureProvider.family<bool, int>((ref, seriesId) async {
  final repo = ref.watch(seriesRepositoryProvider);
  final series = await repo.getSeriesById(seriesId);
  return series?.isVaulted ?? false;
});

class FolderGroup {
  const FolderGroup({
    required this.name,
    required this.path,
    required this.series,
  });

  final String name;
  final String path;
  final List<Series> series;
}

final folderGroupsProvider = FutureProvider<List<FolderGroup>>((ref) async {
  final seriesAsync = ref.watch(allSeriesProvider);
  return seriesAsync.when(
    data: (seriesList) {
      final Map<String, List<Series>> groups = {};
      for (final series in seriesList) {
        final folderPath = p.dirname(series.path);
        final folderName = p.basename(folderPath);
        groups.putIfAbsent(folderPath, () => []);
        groups[folderPath]!.add(series);
      }

      final result = groups.entries.map((e) {
        return FolderGroup(
          name: p.basename(e.key),
          path: e.key,
          series: e.value,
        );
      }).toList();

      result.sort((a, b) => a.name.compareTo(b.name));
      return result;
    },
    loading: () => <FolderGroup>[],
    error: (_, __) => <FolderGroup>[],
  );
});
