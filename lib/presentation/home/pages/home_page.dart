import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/providers/data_providers.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/reading_progress.dart';
import '../../../domain/entities/series.dart';
import '../../../infrastructure/services/library_scanner.dart';
import '../providers/library_folder_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderState = ref.watch(libraryFolderNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comic Viewer'),
        actions: [
          folderState.valueOrNull != null
              ? PopupMenuButton<String>(
                  icon: const Icon(Symbols.more_vert),
                  onSelected: (value) async {
                    if (value == 'refresh') {
                      final folder = ref.read(libraryFolderNotifierProvider).valueOrNull;
                      if (folder != null) {
                        await ref.read(scanNotifierProvider.notifier).scanFolder(folder.path);
                        ref.invalidate(allSeriesProvider);
                      }
                    } else if (value == 'change_folder') {
                      _showChangeFolderDialog(context, ref);
                    } else if (value == 'clear_folder') {
                      await ref.read(libraryFolderNotifierProvider.notifier).clearFolder();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Symbols.refresh, size: 20),
                          SizedBox(width: 8),
                          Text('Pindai Ulang'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'change_folder',
                      child: Row(
                        children: [
                          Icon(Symbols.folder, size: 20),
                          SizedBox(width: 8),
                          Text('Ganti Folder'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_folder',
                      child: Row(
                        children: [
                          Icon(Symbols.delete, size: 20, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Hapus Folder', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: folderState.when(
        data: (folder) {
          if (folder == null) {
            return _FolderPicker(
              onPick: () => ref.read(libraryFolderNotifierProvider.notifier).pickFolder(context),
              onManualInput: () => _showManualInputDialog(context, ref),
            );
          }
          return _LibraryGrid(folderPath: folder.path);
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => _FolderPicker(
          onPick: () => ref.read(libraryFolderNotifierProvider.notifier).pickFolder(context),
          onManualInput: () => _showManualInputDialog(context, ref),
          errorMessage: 'Gagal memuat folder: $error',
        ),
      ),
    );
  }

  void _showManualInputDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Path Folder Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan path folder komik di emulator:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '/sdcard/Comics',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Contoh: /sdcard/Comics',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final path = controller.text.trim();
              if (path.isNotEmpty) {
                Navigator.pop(context);
                await ref.read(libraryFolderNotifierProvider.notifier).setFolderPath(context, path);
              }
            },
            child: const Text('Buka'),
          ),
        ],
      ),
    );
  }

  void _showChangeFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Folder Komik'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan path folder komik:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '/sdcard/Comics',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Contoh: /sdcard/Comics',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final path = controller.text.trim();
              if (path.isNotEmpty) {
                Navigator.pop(context);
                await ref.read(libraryFolderNotifierProvider.notifier).setFolderPath(context, path);
              }
            },
            child: const Text('Buka'),
          ),
        ],
      ),
    );
  }
}

class _FolderPicker extends StatelessWidget {
  const _FolderPicker({required this.onPick, this.errorMessage, this.onManualInput});

  final VoidCallback onPick;
  final String? errorMessage;
  final VoidCallback? onManualInput;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Symbols.folder_open,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Belum ada folder komik dipilih',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onPick,
              child: const Text('Pilih Folder Komik'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onManualInput,
              icon: const Icon(Symbols.edit, size: 18),
              label: const Text('Masukkan Path Manual'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryGrid extends ConsumerWidget {
  const _LibraryGrid({required this.folderPath});

  final String folderPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(allSeriesProvider);
    final recentProgressAsync = ref.watch(recentProgressProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final favoritesAsync = ref.watch(favoriteSeriesProvider);

    ref.listen<AsyncValue<ScanResult?>>(scanNotifierProvider, (prev, next) {
      if (prev?.value == null && next.value != null) {
        ref.invalidate(allSeriesProvider);
      }
    });

    return Column(
      children: [
        _LibraryHeader(folderPath: folderPath),
        _SearchBar(),
        Expanded(
          child: searchQuery.isNotEmpty
              ? searchResults.when(
                  data: (results) {
                    if (results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Symbols.search_off,
                              size: 64,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Tidak ada hasil untuk "$searchQuery"',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      );
                    }
                    return _SearchResults(results: results);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                )
              : seriesAsync.when(
                  data: (series) {
                    if (series.isEmpty) {
                      return _EmptyLibrary(
                        onRefresh: () async {
                          await ref.read(scanNotifierProvider.notifier).scanFolder(folderPath);
                          ref.invalidate(allSeriesProvider);
                        },
                        onGrantPermission: () async {
                          await openAppSettings();
                        },
                      );
                    }
                    return CustomScrollView(
                      slivers: [
                        recentProgressAsync.when(
                          data: (progressList) {
                            if (progressList.isEmpty) {
                              return const SliverToBoxAdapter();
                            }
                            return SliverToBoxAdapter(
                              child: _ContinueReadingSection(progressList: progressList),
                            );
                          },
                          loading: () => const SliverToBoxAdapter(),
                          error: (_, __) => const SliverToBoxAdapter(),
                        ),
                        favoritesAsync.when(
                          data: (favorites) {
                            if (favorites.isEmpty) {
                              return const SliverToBoxAdapter();
                            }
                            return SliverToBoxAdapter(
                              child: _FavoritesSection(favorites: favorites),
                            );
                          },
                          loading: () => const SliverToBoxAdapter(),
                          error: (_, __) => const SliverToBoxAdapter(),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.marginMobile,
                              AppSpacing.md,
                              AppSpacing.marginMobile,
                              AppSpacing.sm,
                            ),
                            child: Text(
                              'Semua Series',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.gutterMobile,
                        crossAxisSpacing: AppSpacing.gutterMobile,
                        childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _SeriesCard(series: series[index]),
                        childCount: series.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.marginMobile),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _LibraryHeader extends ConsumerWidget {
  const _LibraryHeader({required this.folderPath});

  final String folderPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanNotifierProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.folder, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  p.basename(folderPath),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          scanState.when(
            data: (result) {
              if (result == null) return const SizedBox.shrink();
              return Text(
                '${result.seriesCount} series, ${result.chapterCount} chapter',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.outline,
                    ),
              );
            },
            loading: () => Text(
              'Memindai...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.outline,
                  ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onRefresh, this.onGrantPermission});

  final VoidCallback onRefresh;
  final VoidCallback? onGrantPermission;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Symbols.library_music,
            size: 64,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tidak ada series ditemukan',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pastikan folder berisi file PDF',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonal(
            onPressed: onRefresh,
            child: const Text('Pindai Ulang'),
          ),
          if (onGrantPermission != null) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onGrantPermission,
              icon: const Icon(Symbols.settings, size: 18),
              label: const Text('Buka Pengaturan Izin'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeriesCard extends ConsumerWidget {
  const _SeriesCard({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chaptersBySeriesProvider(series.id));
    final thumbnailAsync = ref.watch(thumbnailBySeriesProvider(series.id));

    return GestureDetector(
      onTap: () {
        context.pushNamed('series_detail', extra: series);
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: thumbnailAsync.when(
                data: (thumbnail) {
                  if (thumbnail != null && File(thumbnail.filePath).existsSync()) {
                    return Image.file(
                      File(thumbnail.filePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.surfaceContainerHigh,
                          child: const Icon(
                            Symbols.book,
                            size: 48,
                            color: AppColors.onSurfaceVariant,
                          ),
                        );
                      },
                    );
                  }
                  return Container(
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(
                      Symbols.book,
                      size: 48,
                      color: AppColors.onSurfaceVariant,
                    ),
                  );
                },
                loading: () => Container(
                  color: AppColors.surfaceContainerHigh,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                error: (_, __) => Container(
                  color: AppColors.surfaceContainerHigh,
                  child: const Icon(
                    Symbols.book,
                    size: 48,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  chaptersAsync.when(
                    data: (chapters) => Text(
                      '${chapters.length} chapter',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                    loading: () => const SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(strokeWidth: 1),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueReadingSection extends ConsumerWidget {
  const _ContinueReadingSection({required this.progressList});

  final List<ReadingProgress> progressList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.md,
            AppSpacing.marginMobile,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(Symbols.history, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Lanjutkan Membaca',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
            itemCount: progressList.length,
            itemBuilder: (context, index) {
              return _ContinueReadingCard(progress: progressList[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _ContinueReadingCard extends ConsumerWidget {
  const _ContinueReadingCard({required this.progress});

  final ReadingProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersRepo = ref.read(chaptersRepositoryProvider);

    return FutureBuilder<Chapter?>(
      future: chaptersRepo.getChapterById(progress.chapterId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final chapter = snapshot.data!;

        return GestureDetector(
          onTap: () {
            context.pushNamed('reader', extra: chapter);
          },
          child: Container(
            width: 160,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.comic),
              border: Border.all(color: AppColors.chapterCardBorder),
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Symbols.book,
                  size: 32,
                  color: AppColors.primary,
                ),
                const Spacer(),
                Text(
                  chapter.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Halaman ${progress.currentPage + 1}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.sm,
        AppSpacing.marginMobile,
        AppSpacing.sm,
      ),
      child: TextField(
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: 'Cari series...',
          prefixIcon: const Icon(Symbols.search, color: AppColors.onSurfaceVariant),
          suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
              ? IconButton(
                  icon: const Icon(Symbols.close, color: AppColors.onSurfaceVariant),
                  onPressed: () {
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceContainerHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results});

  final List<Series> results;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final series = results[index];
        return _SearchResultCard(series: series);
      },
    );
  }
}

class _SearchResultCard extends ConsumerWidget {
  const _SearchResultCard({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsync = ref.watch(thumbnailBySeriesProvider(series.id));

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: thumbnailAsync.when(
          data: (thumbnail) {
            if (thumbnail != null && File(thumbnail.filePath).existsSync()) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.file(
                  File(thumbnail.filePath),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              );
            }
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Symbols.book, color: AppColors.onSurfaceVariant),
            );
          },
          loading: () => const SizedBox(
            width: 48,
            height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Symbols.book, color: AppColors.onSurfaceVariant),
          ),
        ),
        title: Text(
          series.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Symbols.chevron_right, color: AppColors.outline),
        onTap: () {
          context.pushNamed('series_detail', extra: series);
        },
      ),
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({required this.favorites});

  final List<Series> favorites;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.md,
            AppSpacing.marginMobile,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(Symbols.favorite, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Favorites',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return _FavoriteCard(series: favorites[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _FavoriteCard extends ConsumerWidget {
  const _FavoriteCard({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsync = ref.watch(thumbnailBySeriesProvider(series.id));

    return GestureDetector(
      onTap: () {
        context.pushNamed('series_detail', extra: series);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.comic),
          border: Border.all(color: AppColors.chapterCardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: thumbnailAsync.when(
          data: (thumbnail) {
            if (thumbnail != null && File(thumbnail.filePath).existsSync()) {
              return Image.file(
                File(thumbnail.filePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Symbols.favorite, color: AppColors.primary);
                },
              );
            }
            return const Icon(Symbols.favorite, color: AppColors.primary);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const Icon(Symbols.favorite, color: AppColors.primary),
        ),
      ),
    );
  }
}
