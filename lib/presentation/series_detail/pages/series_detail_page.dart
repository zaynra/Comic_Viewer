import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/providers/data_providers.dart';
import '../../../domain/entities/bookmark.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/series.dart';
import '../../../domain/entities/thumbnail.dart';
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
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 48, height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(3)),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const Text('Urutkan Chapter',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                              const SizedBox(height: AppSpacing.md),
                              ListTile(
                                leading: const Icon(Icons.sort_by_alpha, color: AppColors.primary),
                                title: const Text('Nomor (ASC)', style: TextStyle(color: AppColors.onSurface)),
                                trailing: const Icon(Icons.check, color: AppColors.primary, size: 18),
                                onTap: () => Navigator.pop(ctx),
                              ),
                              ListTile(
                                leading: const Icon(Icons.sort_by_alpha, color: AppColors.onSurfaceVariant),
                                title: const Text('Nomor (DESC)', style: TextStyle(color: AppColors.onSurface)),
                                onTap: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
          icon: Icon(
            series.isVaulted
                ? Symbols.lock_open
                : Symbols.lock,
            color: series.isVaulted
                ? AppColors.primary
                : AppColors.onSurface,
          ),
          onPressed: () async {
            await ref.read(seriesRepositoryProvider).toggleVault(series.id);
            ref.invalidate(allSeriesProvider);
            ref.invalidate(vaultedSeriesProvider);
            ref.invalidate(isVaultedProvider(series.id));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    series.isVaulted
                        ? 'Dihapus dari Vault'
                        : 'Dipindah ke Vault',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
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
                  _CoverThumbnail(thumbnailAsync: thumbnailAsync, series: series),
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

class _CoverThumbnail extends ConsumerWidget {
  const _CoverThumbnail({required this.thumbnailAsync, required this.series});

  final AsyncValue<Thumbnail?> thumbnailAsync;
  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnail = thumbnailAsync.valueOrNull;

    return GestureDetector(
      onTap: () => _showCoverOptions(context, ref, series, thumbnail),
      child: SizedBox(
        width: 192,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
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
                      data: (t) {
                        if (t != null && File(t.filePath).existsSync()) {
                          return Image.file(
                            File(t.filePath),
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
                ),
                if (thumbnail != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _ThumbnailSourceBadge(thumbnail: thumbnail),
                  ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                      onPressed: () => _showCoverOptions(context, ref, series, thumbnail),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (thumbnail != null)
              _ThumbnailSourceBadge(thumbnail: thumbnail, label: true),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailSourceBadge extends StatelessWidget {
  const _ThumbnailSourceBadge({required this.thumbnail, this.label = false});

  final Thumbnail thumbnail;
  final bool label;

  @override
  Widget build(BuildContext context) {
    final isCustom = thumbnail.isCustom;
    final bg = isCustom ? Colors.amber.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.2);
    final fg = isCustom ? Colors.black : Colors.white70;
    final text = label ? (isCustom ? 'Custom Cover' : 'Auto-generated') : (isCustom ? 'Custom' : 'Auto');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: label ? 8 : 6, vertical: label ? 2 : 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: label ? 11 : 10, fontWeight: label ? FontWeight.w500 : null),
      ),
    );
  }
}

void _showCoverOptions(BuildContext context, WidgetRef ref, Series series, Thumbnail? thumbnail) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceContainerLow,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Cover Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
            title: const Text('Regenerate from PDF'),
            subtitle: const Text('Re-render cover from first page'),
            onTap: () async {
              Navigator.pop(ctx);
              final service = ref.read(thumbnailServiceProvider);
              await service.regenerateThumbnail(series.id, series.path);
              ref.invalidate(thumbnailBySeriesProvider(series.id));
            },
          ),
          ListTile(
            leading: const Icon(Icons.image, color: AppColors.onSurfaceVariant),
            title: const Text('Choose Custom Image'),
            subtitle: const Text('Pick an image from gallery'),
            onTap: () async {
              Navigator.pop(ctx);
              final result = await FilePicker.platform.pickFiles(type: FileType.image);
              if (result != null && result.files.single.path != null) {
                final service = ref.read(thumbnailServiceProvider);
                await service.setCustomCover(series.id, series.path, result.files.single.path!);
                ref.invalidate(thumbnailBySeriesProvider(series.id));
              }
            },
          ),
          if (thumbnail?.isCustom == true)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Remove Custom Cover', style: TextStyle(color: Colors.redAccent)),
              subtitle: const Text('Revert to auto-generated'),
              onTap: () async {
                Navigator.pop(ctx);
                final service = ref.read(thumbnailServiceProvider);
                await service.deleteThumbnail(series.id);
                ref.invalidate(thumbnailBySeriesProvider(series.id));
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _confirmDeleteSeries(BuildContext context, WidgetRef ref, Series series) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      title: const Text('Hapus Series'),
      content: Text('Yakin ingin menghapus "${series.name}"? Tindakan ini tidak bisa dibatalkan.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await ref.read(seriesRepositoryProvider).deleteSeries(series.id);
    ref.invalidate(allSeriesProvider);
    ref.invalidate(favoriteSeriesProvider);
    if (context.mounted) Navigator.of(context).pop();
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
    final isFavAsync = ref.watch(isFavoriteProvider(series.id));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Favorite button
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorderSubtle),
            ),
            child: IconButton(
              icon: isFavAsync.when(
                data: (isFav) => Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : AppColors.onSurfaceVariant,
                ),
                loading: () => const Icon(Icons.favorite_border, color: AppColors.onSurfaceVariant),
                error: (_, __) => const Icon(Icons.favorite_border, color: AppColors.onSurfaceVariant),
              ),
              onPressed: () async {
                await ref.read(favoritesRepositoryProvider).toggleFavorite(series.id);
                ref.invalidate(isFavoriteProvider(series.id));
                ref.invalidate(favoriteSeriesProvider);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Resume button
          Expanded(
            child: PrimaryButton(
              label: 'Lanjut Baca',
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
              icon: const Icon(Icons.bookmark_add_outlined, color: AppColors.onSurfaceVariant),
              tooltip: 'Bookmark',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surfaceContainer,
                    title: const Text('Bookmark'),
                    content: const Text('Bookmark halaman saat ini?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                      TextButton(
                        onPressed: () {
                          ref.read(bookmarkRepositoryProvider).addBookmark(
                            Bookmark(id: 0, chapterId: 0, page: 0, createdAt: DateTime.now()),
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bookmark ditambahkan')),
                          );
                        },
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                );
              },
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
              icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceVariant),
              tooltip: 'Lainnya',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 48, height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(3)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ListTile(
                          leading: const Icon(Icons.lock_outline, color: AppColors.onSurfaceVariant),
                          title: Text(series.isVaulted ? 'Hapus dari Vault' : 'Pindah ke Vault',
                            style: const TextStyle(color: AppColors.onSurface)),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await ref.read(seriesRepositoryProvider).toggleVault(series.id);
                            ref.invalidate(allSeriesProvider);
                            ref.invalidate(vaultedSeriesProvider);
                            ref.invalidate(isVaultedProvider(series.id));
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.image_outlined, color: AppColors.onSurfaceVariant),
                          title: const Text('Edit Cover', style: TextStyle(color: AppColors.onSurface)),
                          onTap: () {
                            Navigator.pop(ctx);
                            _showCoverOptions(context, ref, series, null);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: AppColors.error),
                          title: const Text('Hapus Series', style: TextStyle(color: AppColors.error)),
                          onTap: () {
                            Navigator.pop(ctx);
                            _confirmDeleteSeries(context, ref, series);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
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
    return chaptersAsync.when(
      data: (chapters) {
        if (chapters.isEmpty) return const SizedBox.shrink();
        final inProgress = chapters.where((c) => c.currentPage > 0 && !c.isRead).toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              if (inProgress.isNotEmpty)
                Expanded(
                  child: PrimaryButton(
                    label: 'Lanjutkan Membaca',
                    icon: Icons.play_circle,
                    onPressed: () => context.pushNamed('reader', extra: inProgress.first),
                  ),
                ),
              if (inProgress.isNotEmpty) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.pushNamed('reader', extra: chapters.first),
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Baca dari Awal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.errorContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Gagal memuat chapter: $e',
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
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

            // Action
            if (isRead)
              const Icon(
                Icons.download_done,
                color: AppColors.onSurfaceVariant,
                size: 20,
              )
            else if (!isActive)
              const Icon(
                Icons.download,
                color: AppColors.onSurfaceVariant,
                size: 20,
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
