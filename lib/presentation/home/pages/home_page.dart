import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/providers/data_providers.dart';
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
  bool _vaultUnlocked = false;
  final _tabs = ['All Items', 'Recent', 'Vault'];

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanNotifierProvider);

    ref.listen<AsyncValue<ScanResult?>>(scanNotifierProvider, (prev, next) {
      if (prev?.value == null && next.value != null) {
        ref.invalidate(allSeriesProvider);
        ref.invalidate(recentSeriesProvider);
        ref.invalidate(vaultedSeriesProvider);
      }
    });

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _GlassTopBar(
                folderPath: widget.folderPath,
                scanState: scanState,
                onAddFolder: () => _addFolderToLibrary(ref),
              ),
            ),
            SliverToBoxAdapter(
              child: _FilterTabs(
                tabs: _tabs,
                selectedIndex: _selectedTab,
                onTap: (index) {
                  if (index == 2 && !_vaultUnlocked) {
                    _showPinDialog();
                  } else {
                    setState(() => _selectedTab = index);
                  }
                },
              ),
            ),
            if (_selectedTab == 0)
              _buildAllItemsSliver(ref)
            else if (_selectedTab == 1)
              _buildRecentSliver(ref)
            else
              _buildVaultSliver(ref),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
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

  Widget _buildAllItemsSliver(WidgetRef ref) {
    final seriesAsync = ref.watch(allSeriesProvider);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
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
          return _ShelfGrid(series: series);
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
    );
  }

  Widget _buildRecentSliver(WidgetRef ref) {
    final recentAsync = ref.watch(recentSeriesProvider);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      sliver: recentAsync.when(
        data: (series) {
          if (series.isEmpty) {
            return SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: AppColors.outline,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Tidak ada aktivitas terbaru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return _ShelfGrid(series: series);
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
    );
  }

  void _showPinDialog() {
    final controllers = List.generate(4, (_) => TextEditingController());
    final focusNodes = List.generate(4, (_) => FocusNode());
    String? error;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.surfaceContainer,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Masukkan PIN Vault',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan PIN 4 digit untuk akses Vault',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        return Container(
                          width: 52,
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: AppRadius.radiusMd,
                            border: Border.all(
                              color: error != null
                                  ? AppColors.error
                                  : AppColors.outlineVariant.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: controllers[i],
                            focusNode: focusNodes[i],
                            textAlign: TextAlign.center,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && i < 3) {
                                focusNodes[i + 1].requestFocus();
                              }
                              if (value.isEmpty && i > 0) {
                                focusNodes[i - 1].requestFocus();
                              }
                              if (controllers.every((c) => c.text.isNotEmpty)) {
                                final pin = controllers.map((c) => c.text).join();
                                if (pin == '2305') {
                                  Navigator.pop(context);
                                  setState(() {
                                    _vaultUnlocked = true;
                                    _selectedTab = 2;
                                  });
                                } else {
                                  setDialogState(() => error = 'PIN salah');
                                  for (final c in controllers) {
                                    c.clear();
                                  }
                                  focusNodes[0].requestFocus();
                                }
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerHigh,
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVaultSliver(WidgetRef ref) {
    final vaultedAsync = ref.watch(vaultedSeriesProvider);
    return vaultedAsync.when(
      data: (series) {
        if (series.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
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
                        Icons.lock_outline_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Vault kosong',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Pilih folder untuk menambahkan komik ke Vault',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Pilih Folder untuk Vault',
                      icon: Icons.folder_open,
                      onPressed: () => _pickVaultFolder(ref),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          sliver: _ShelfGrid(series: series),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _pickVaultFolder(WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih folder untuk Vault',
    );
    if (result == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memindai folder untuk Vault...'),
        duration: Duration(seconds: 2),
      ),
    );

    await ref.read(scanNotifierProvider.notifier).scanFolder(result);

    final repo = ref.read(seriesRepositoryProvider);
    final allSeries = await repo.getAllSeries();
    for (final s in allSeries) {
      if (!s.isVaulted && s.path.startsWith(result)) {
        await repo.toggleVault(s.id);
      }
    }
    ref.invalidate(vaultedSeriesProvider);
    ref.invalidate(allSeriesProvider);
    ref.invalidate(recentSeriesProvider);
  }

  Future<void> _addFolderToLibrary(WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Tambah folder komik',
    );
    if (result == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memindai folder baru...'),
        duration: Duration(seconds: 2),
      ),
    );

    await ref.read(scanNotifierProvider.notifier).scanFolder(result);
    ref.invalidate(allSeriesProvider);
    ref.invalidate(recentSeriesProvider);
    ref.invalidate(vaultedSeriesProvider);
  }
}

class _GlassTopBar extends StatelessWidget {
  const _GlassTopBar({
    required this.folderPath,
    required this.scanState,
    required this.onAddFolder,
  });

  final String folderPath;
  final AsyncValue<ScanResult?> scanState;
  final VoidCallback onAddFolder;

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
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.asset(
              'assets/images/or_logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
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
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            'Omnivious Reader',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onAddFolder,
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

class _ShelfGrid extends StatelessWidget {
  const _ShelfGrid({required this.series});

  final List<Series> series;

  @override
  Widget build(BuildContext context) {
    const int columnsPerRow = 2;
    const double spacing = AppSpacing.md;
    const double padding = AppSpacing.md;
    final int rowCount = (series.length / columnsPerRow).ceil();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, rowIndex) {
          final int startIndex = rowIndex * columnsPerRow;
          final int endIndex = (startIndex + columnsPerRow).clamp(0, series.length);
          final rowSeries = series.sublist(startIndex, endIndex);

          return Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: (MediaQuery.of(context).size.width - padding * 2 - spacing) / 2 * 1.5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < rowSeries.length; i++) ...[
                        Expanded(
                          child: _BookCard(series: rowSeries[i]),
                        ),
                        if (i < rowSeries.length - 1)
                          const SizedBox(width: spacing),
                      ],
                      if (rowSeries.length < columnsPerRow)
                        for (int i = rowSeries.length; i < columnsPerRow; i++) ...[
                          const Expanded(child: SizedBox()),
                          if (i < columnsPerRow - 1)
                            const SizedBox(width: spacing),
                        ],
                    ],
                  ),
                ),
                Container(
                  height: 6,
                  margin: const EdgeInsets.only(top: 4, bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: const Border(
                      top: BorderSide(
                        color: Colors.white10,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        childCount: rowCount,
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  const _BookCard({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsync = ref.watch(thumbnailBySeriesProvider(series.id));
    final chaptersAsync = ref.watch(chaptersBySeriesProvider(series.id));

    return GestureDetector(
      onTap: () => context.pushNamed('series_detail', extra: series),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.comic,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        series.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: chaptersAsync.when(
                              data: (chapters) {
                                if (chapters.isEmpty) return const SizedBox.shrink();
                                final readCount = chapters.where((c) => c.isRead).length;
                                final progress = readCount / chapters.length;
                                return Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
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
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          chaptersAsync.when(
                            data: (chapters) {
                              if (chapters.isEmpty) return const SizedBox.shrink();
                              final readCount = chapters.where((c) => c.isRead).length;
                              final progress = readCount / chapters.length;
                              final percent = (progress * 100).round();
                              return Text(
                                '$percent%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          size: 48,
          color: AppColors.onSurfaceVariant,
        ),
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
