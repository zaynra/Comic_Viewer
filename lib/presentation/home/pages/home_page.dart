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
import '../../../infrastructure/services/library_scanner.dart';
import '../../shared/widgets/widgets.dart';
import '../providers/library_folder_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderState = ref.watch(libraryFolderNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: folderState.when(
        data: (folder) {
          if (folder == null) {
            return _FolderPicker(
              onPick: () => ref.read(libraryFolderNotifierProvider.notifier).pickFolder(context),
              onManualInput: () => _showManualInputDialog(context, ref),
            );
          }
          return _LibraryView(folderPath: folder.path);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
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
        backgroundColor: AppColors.surfaceContainer,
        title: const Text('Path Folder Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan path folder komik di emulator:',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: '/sdcard/Comics',
                hintStyle: const TextStyle(color: AppColors.outline),
                filled: true,
                fillColor: AppColors.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
              autofocus: true,
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorderSubtle),
              ),
              child: const Icon(
                Icons.folder_open,
                size: 48,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Belum ada folder komik dipilih',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 14),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Pilih Folder Komik',
              icon: Icons.folder,
              onPressed: onPick,
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

class _LibraryView extends ConsumerStatefulWidget {
  const _LibraryView({required this.folderPath});

  final String folderPath;

  @override
  ConsumerState<_LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends ConsumerState<_LibraryView> {
  int _selectedTab = 0;
  final _tabs = ['All Items', 'Folders', 'Recent', 'Favorites'];

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(allSeriesProvider);
    final scanState = ref.watch(scanNotifierProvider);

    ref.listen<AsyncValue<ScanResult?>>(scanNotifierProvider, (prev, next) {
      if (prev?.value == null && next.value != null) {
        ref.invalidate(allSeriesProvider);
      }
    });

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: _GlassTopBar(
                folderPath: widget.folderPath,
                scanState: scanState,
              ),
            ),

            // Filter Tabs
            SliverToBoxAdapter(
              child: _FilterTabs(
                tabs: _tabs,
                selectedIndex: _selectedTab,
                onTap: (index) => setState(() => _selectedTab = index),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                120, // Space for bottom nav
              ),
              sliver: seriesAsync.when(
                data: (series) {
                  if (series.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptyState(
                        onRefresh: () async {
                          await ref.read(scanNotifierProvider.notifier).scanFolder(widget.folderPath);
                          ref.invalidate(allSeriesProvider);
                        },
                      ),
                    );
                  }

                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ComicCard(series: series[index]),
                      childCount: series.length,
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
              ),
            ),
          ],
        ),

        // Bottom Navigation
        GlassBottomNav(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) context.push('/history');
            if (index == 2) context.push('/settings');
          },
          items: const [
            GlassBottomNavItem(
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view,
              label: 'Library',
            ),
            GlassBottomNavItem(
              icon: Icons.history_outlined,
              activeIcon: Icons.history,
              label: 'History',
            ),
            GlassBottomNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Settings',
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassTopBar extends StatelessWidget {
  const _GlassTopBar({required this.folderPath, required this.scanState});

  final String folderPath;
  final AsyncValue<ScanResult?> scanState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Center(
              child: Text(
                'OR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            'OmnivousReader',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.create_new_folder_outlined,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.search,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : Colors.transparent,
                borderRadius: AppRadius.pill,
                border: isSelected
                    ? null
                    : Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.05,
                  color: isSelected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ComicCard extends ConsumerWidget {
  const _ComicCard({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsync = ref.watch(thumbnailBySeriesProvider(series.id));
    final chaptersAsync = ref.watch(chaptersBySeriesProvider(series.id));

    return GestureDetector(
      onTap: () => context.pushNamed('series_detail', extra: series),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.comic,
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.comic,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    thumbnailAsync.when(
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
                    // Progress bar at bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _ProgressBar(chaptersAsync: chaptersAsync),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Title
          Text(
            series.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Chapter count
          chaptersAsync.when(
            data: (chapters) => Text(
              '${chapters.length} chapter',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.05,
                color: AppColors.outline,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
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
          size: 48,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.chaptersAsync});

  final AsyncValue<List<Chapter>> chaptersAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.8),
      ),
      child: chaptersAsync.when(
        data: (chapters) {
          if (chapters.isEmpty) return const SizedBox.shrink();
          final readCount = chapters.where((c) => c.isRead).length;
          final progress = readCount / chapters.length;
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorderSubtle),
            ),
            child: const Icon(
              Icons.auto_stories,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Tidak ada series ditemukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Pastikan folder berisi file PDF',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Pindai Ulang',
            icon: Icons.refresh,
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
