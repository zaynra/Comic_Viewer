import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/providers/data_providers.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/series.dart';

class SeriesDetailPage extends ConsumerWidget {
  const SeriesDetailPage({super.key, required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chaptersBySeriesProvider(series.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _SeriesHeader(series: series),
          SliverToBoxAdapter(
            child: _SeriesInfo(series: series),
          ),
          SliverToBoxAdapter(
            child: _ActionButtons(chaptersAsync: chaptersAsync, series: series),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.lg,
                AppSpacing.marginMobile,
                AppSpacing.sm,
              ),
              child: Text(
                'Chapters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          _ChapterList(chaptersAsync: chaptersAsync),
        ],
      ),
    );
  }
}

class _SeriesHeader extends ConsumerWidget {
  const _SeriesHeader({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsync = ref.watch(thumbnailBySeriesProvider(series.id));

    return SliverAppBar(
      expandedHeight: 530,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Symbols.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            thumbnailAsync.when(
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
                          size: 96,
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
                    size: 96,
                    color: AppColors.onSurfaceVariant,
                  ),
                );
              },
              loading: () => Container(
                color: AppColors.surfaceContainerHigh,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (_, __) => Container(
                color: AppColors.surfaceContainerHigh,
                child: const Icon(
                  Symbols.book,
                  size: 96,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.marginMobile,
              right: AppSpacing.marginMobile,
              bottom: AppSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ChipBadges(),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              series.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              series.path,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                               ),
                          ],
                        ),
                      ),
                      _FavoriteButton(seriesId: series.id),
                    ],
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

class _ChipBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          label: 'Local',
          icon: Symbols.download_done,
        ),
        const SizedBox(width: AppSpacing.xs),
        _Chip(label: 'PDF'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.outline),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.seriesId});

  final int seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavoriteAsync = ref.watch(isFavoriteProvider(seriesId));
    final isFavorite = isFavoriteAsync.valueOrNull ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: IconButton(
        icon: Icon(
          Symbols.favorite,
          color: isFavorite ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
        onPressed: () async {
          await ref.read(favoritesRepositoryProvider).toggleFavorite(seriesId);
          ref.invalidate(isFavoriteProvider(seriesId));
          ref.invalidate(favoriteSeriesProvider);
        },
      ),
    );
  }
}

class _SeriesInfo extends StatelessWidget {
  const _SeriesInfo({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.chaptersAsync, required this.series});

  final AsyncValue<List<Chapter>> chaptersAsync;
  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () {
                chaptersAsync.whenData((chapters) {
                  if (chapters.isNotEmpty) {
                    context.pushNamed('reader', extra: chapters.first);
                  }
                });
              },
              child: const Text('Mulai Baca'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                chaptersAsync.whenData((chapters) {
                  if (chapters.isNotEmpty) {
                    context.pushNamed('reader', extra: chapters.first);
                  }
                });
              },
              child: const Text('Baca dari Awal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterList extends ConsumerWidget {
  const _ChapterList({required this.chaptersAsync});

  final AsyncValue<List<Chapter>> chaptersAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return chaptersAsync.when(
      data: (chapters) {
        if (chapters.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.marginMobile),
              child: Center(
                child: Text('Tidak ada chapter'),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ChapterCard(chapter: chapters[index]),
              childCount: chapters.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final isRead = chapter.isRead;
    final hasProgress = chapter.currentPage > 0 && !isRead;

    return GestureDetector(
      onTap: () {
        context.pushNamed('reader', extra: chapter);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Chapter ${chapter.sortOrder}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                        if (isRead) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Symbols.download_done,
                            size: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapter.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            decoration:
                                isRead ? TextDecoration.lineThrough : null,
                            decorationColor: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasProgress) ...[
                      const SizedBox(height: 8),
                      _ProgressBar(progress: chapter.progress),
                    ],
                  ],
                ),
              ),
              if (isRead)
                const Icon(
                  Symbols.check_circle,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.progressFill,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
