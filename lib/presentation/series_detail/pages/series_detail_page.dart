import 'dart:io';
import 'dart:ui' as ui;

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
import '../../shared/widgets/widgets.dart';

class SeriesDetailPage extends ConsumerWidget {
  const SeriesDetailPage({super.key, required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chaptersBySeriesProvider(series.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _HeroHeader(series: series),
          SliverToBoxAdapter(
            child: _MetadataSection(series: series, chaptersAsync: chaptersAsync),
          ),
          SliverToBoxAdapter(
            child: _SynopsisSection(series: series),
          ),
          SliverToBoxAdapter(
            child: _GenresSection(series: series),
          ),
          SliverToBoxAdapter(
            child: _ActionButtons(chaptersAsync: chaptersAsync),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  const Text(
                    'Recent Chapters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.sort, size: 16),
                    label: const Text('Sort'),
                  ),
                ],
              ),
            ),
          ),
          _ChapterList(chaptersAsync: chaptersAsync),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends ConsumerWidget {
  const _HeroHeader({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsync = ref.watch(thumbnailBySeriesProvider(series.id));

    return SliverAppBar(
      expandedHeight: 530,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Symbols.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Symbols.search),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred background
            thumbnailAsync.when(
              data: (thumbnail) {
                if (thumbnail != null && File(thumbnail.filePath).existsSync()) {
                  return ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Opacity(
                      opacity: 0.4,
                      child: Image.file(
                        File(thumbnail.filePath),
                        fit: BoxFit.cover,
                        scale: 1.1,
                      ),
                    ),
                  );
                }
                return Container(color: AppColors.background);
              },
              loading: () => Container(color: AppColors.background),
              error: (_, __) => Container(color: AppColors.background),
            ),

            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background,
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Foreground content
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.xl,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Cover thumbnail
                  _CoverThumbnail(thumbnailAsync: thumbnailAsync),
                  const SizedBox(width: AppSpacing.md),

                  // Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          series.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            letterSpacing: -0.02,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (series.author != null)
                          _MetadataRow(
                            icon: Symbols.draw,
                            text: 'Writer: ${series.author}',
                          ),
                        if (series.description != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _MetadataRow(
                            icon: Symbols.book,
                            text: series.description!,
                          ),
                        ],
                      ],
                    ),
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

class _CoverThumbnail extends StatelessWidget {
  const _CoverThumbnail({required this.thumbnailAsync});

  final AsyncValue<dynamic> thumbnailAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 192,
      height: 288,
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusXl,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.glassBorderSubtle,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusXl,
        child: thumbnailAsync.when(
          data: (thumbnail) {
            if (thumbnail != null && File(thumbnail.filePath).existsSync()) {
              return Image.file(
                File(thumbnail.filePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PlaceholderCover(),
              );
            }
            return _PlaceholderCover();
          },
          loading: () => _PlaceholderCover(),
          error: (_, __) => _PlaceholderCover(),
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(
          Icons.auto_stories,
          size: 64,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MetadataSection extends ConsumerWidget {
  const _MetadataSection({required this.series, required this.chaptersAsync});

  final Series series;
  final AsyncValue<List<Chapter>> chaptersAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Resume button
          Expanded(
            child: PrimaryButton(
              label: 'Resume Reading',
              icon: Icons.play_circle,
              onPressed: () {
                chaptersAsync.whenData((chapters) {
                  if (chapters.isNotEmpty) {
                    context.pushNamed('reader', extra: chapters.first);
                  }
                });
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Bookmark button
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorderSubtle),
            ),
            child: IconButton(
              icon: Icon(
                Symbols.bookmark_add,
                color: AppColors.onSurfaceVariant,
              ),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // More button
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorderSubtle),
            ),
            child: IconButton(
              icon: Icon(
                Symbols.more_vert,
                color: AppColors.onSurfaceVariant,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.chaptersAsync});

  final AsyncValue<List<Chapter>> chaptersAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}

class _SynopsisSection extends StatelessWidget {
  const _SynopsisSection({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    if (series.description == null || series.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYNOPSIS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.15,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: AppRadius.radiusLg,
              border: Border.all(
                color: AppColors.glassBorderSubtle,
                width: 0.5,
              ),
            ),
            child: Text(
              series.description!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenresSection extends StatelessWidget {
  const _GenresSection({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    if (series.genres == null || series.genres!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GENRES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.15,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: series.genres!.map((genre) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  genre,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              );
            }).toList(),
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
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  'Tidak ada chapter',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ChapterItem(chapter: chapters[index]),
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

class _ChapterItem extends StatelessWidget {
  const _ChapterItem({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final isRead = chapter.isRead;
    final isActive = chapter.currentPage > 0 && !isRead;

    return GestureDetector(
      onTap: () => context.pushNamed('reader', extra: chapter),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.surfaceContainerLow
              : AppColors.surfaceContainerLowest,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail placeholder
            Container(
              width: 48,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.glassBorderSubtle,
                  width: 0.5,
                ),
              ),
              child: isActive
                  ? const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    )
                  : isRead
                      ? const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.onSurfaceVariant,
                          size: 24,
                        )
                      : Center(
                          child: Text(
                            '#${chapter.sortOrder}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                      color: isActive
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${chapter.totalPages} Pages',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.05,
                      color: AppColors.surfaceTint,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    _ChapterProgress(progress: chapter.progress),
                  ],
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _ChapterProgress extends StatelessWidget {
  const _ChapterProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${(progress * 100).round()}%',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
