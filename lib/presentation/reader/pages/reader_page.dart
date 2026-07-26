import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/providers/data_providers.dart';
import '../../../domain/entities/bookmark.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/reading_progress.dart';
import '../../../infrastructure/services/pdf_renderer.dart';
import '../../settings/providers/settings_provider.dart';
import '../../shared/widgets/widgets.dart';

class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({super.key, required this.chapter});

  final Chapter chapter;

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late PdfRenderer _renderer;
  bool _isLoading = true;
  String? _error;
  bool _showControls = false;
  double _scale = 1.0;
  ReadingProgress? _savedProgress;
  List<Chapter> _siblingChapters = [];
  int _currentChapterIndex = 0;
  Timer? _autoNextTimer;
  bool _showAutoNextDialog = false;
  bool _isBookmarked = false;
  Bookmark? _currentBookmark;

  Timer? _hideControlsTimer;
  Timer? _highResUpgradeTimer;
  Timer? _memoryTimer;
  final ScrollController _verticalScrollController = ScrollController();
  final TransformationController _transformationController = TransformationController();

  double _avgPageHeight = 0;
  int _lastFirstVisible = -1;
  int _lastLastVisible = -1;

  @override
  void initState() {
    super.initState();
    _renderer = PdfRenderer(widget.chapter.filePath);
    _initRenderer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _verticalScrollController.addListener(_onScroll);
    _memoryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _renderer.checkMemoryPressure();
    });
    setState(() { _showControls = true; });
    _startAutoHideTimer();
  }

  Future<void> _initRenderer() async {
    try {
      await _renderer.open();

      _savedProgress = await ref
          .read(readingProgressRepositoryProvider)
          .getProgressByChapterId(widget.chapter.id);

      if (_savedProgress != null && _savedProgress!.currentPage > 0) {
        await _renderer.goToPage(_savedProgress!.currentPage);
      }

      final chapters = await ref
          .read(chaptersRepositoryProvider)
          .getChaptersBySeriesId(widget.chapter.seriesId);

      await _checkBookmark();
      await _prefetchInitialPages();

      setState(() {
        _siblingChapters = chapters;
        _currentChapterIndex = chapters.indexWhere((c) => c.id == widget.chapter.id);
        _isLoading = false;
      });

      _applyOrientation();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _prefetchInitialPages() async {
    await _renderer.prefetchRange(0, 4, RenderQuality.lowRes);
    unawaited(_renderer.prefetchHighRes(0));
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    _hideControlsTimer?.cancel();
    _highResUpgradeTimer?.cancel();
    _memoryTimer?.cancel();
    _saveProgress();
    _renderer.disposeCache();
    _renderer.close();
    _verticalScrollController.removeListener(_onScroll);
    _verticalScrollController.dispose();
    _transformationController.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  void _applyOrientation() {
    final settings = ref.read(settingsProvider);
    switch (settings.orientationMode) {
      case OrientationMode.portrait:
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        break;
      case OrientationMode.landscape:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case OrientationMode.auto:
        SystemChrome.setPreferredOrientations([]);
        break;
    }

    if (settings.keepScreenOn) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<void> _saveProgress() async {
    if (!mounted || !_renderer.hasDocument) return;
    try {
      final progress = ReadingProgress(
        id: _savedProgress?.id ?? 0,
        chapterId: widget.chapter.id,
        currentPage: _renderer.currentPage,
        zoomLevel: _scale,
        lastOpenedAt: DateTime.now(),
      );
      await ref.read(readingProgressRepositoryProvider).saveProgress(progress);
    } catch (_) {}
  }

  Future<void> _checkBookmark() async {
    final repo = ref.read(bookmarkRepositoryProvider);
    final bookmarked = await repo.isBookmarked(
      widget.chapter.id,
      _renderer.currentPage,
    );
    final bookmark = await repo.getBookmarkAtPage(
      widget.chapter.id,
      _renderer.currentPage,
    );
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
        _currentBookmark = bookmark;
      });
    }
  }

  void _onScroll() {
    if (!_verticalScrollController.hasClients) return;

    final position = _verticalScrollController.position;
    final viewportHeight = position.viewportDimension;
    final scrollOffset = position.pixels;

    if (_avgPageHeight == 0 && _renderer.hasDocument) {
      _updateAvgPageHeight();
    }

    if (_avgPageHeight == 0) return;

    final firstVisible = (scrollOffset / _avgPageHeight).floor().clamp(0, _renderer.totalPages - 1);
    final lastVisible = ((scrollOffset + viewportHeight) / _avgPageHeight).ceil().clamp(0, _renderer.totalPages - 1);

    if (firstVisible != _lastFirstVisible || lastVisible != _lastLastVisible) {
      _lastFirstVisible = firstVisible;
      _lastLastVisible = lastVisible;

      final prefetchStart = (firstVisible - 2).clamp(0, _renderer.totalPages - 1);
      final prefetchEnd = (lastVisible + 2).clamp(0, _renderer.totalPages - 1);
      _renderer.prefetchRange(prefetchStart, prefetchEnd, RenderQuality.lowRes);

      _highResUpgradeTimer?.cancel();
      _highResUpgradeTimer = Timer(const Duration(seconds: 2), () {
        for (int i = firstVisible; i <= lastVisible; i++) {
          _renderer.prefetchHighRes(i);
        }
      });
    }
  }

  Future<void> _updateAvgPageHeight() async {
    final firstPage = await _renderer.getPageImage(0, quality: RenderQuality.lowRes);
    if (firstPage != null) {
      _avgPageHeight = firstPage.height.toDouble();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    _hideControlsTimer?.cancel();
    if (_showControls) {
      _startAutoHideTimer();
    }
  }

  void _startAutoHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  Future<void> _nextPage() async {
    if (_renderer.canGoNext) {
      await _renderer.nextPage();
      await _checkBookmark();
    } else if (_hasNextChapter) {
      final settings = ref.read(settingsProvider);
      if (settings.autoContinue) {
        _goToNextChapter();
      } else {
        _showAutoNextChapterDialog();
      }
    }
  }

  Future<void> _previousPage() async {
    if (_renderer.canGoPrevious) {
      await _renderer.previousPage();
      await _checkBookmark();
    } else if (_hasPreviousChapter) {
      _goToPreviousChapter();
    }
  }

  bool get _hasPreviousChapter => _currentChapterIndex > 0;
  bool get _hasNextChapter => _currentChapterIndex < _siblingChapters.length - 1;

  Chapter? get _previousChapter =>
      _hasPreviousChapter ? _siblingChapters[_currentChapterIndex - 1] : null;

  Chapter? get _nextChapter =>
      _hasNextChapter ? _siblingChapters[_currentChapterIndex + 1] : null;

  void _showAutoNextChapterDialog() {
    _autoNextTimer?.cancel();
    setState(() {
      _showAutoNextDialog = true;
      _showControls = false;
    });

    _autoNextTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _showAutoNextDialog) {
        setState(() {
          _showAutoNextDialog = false;
        });
        _goToNextChapter();
      }
    });
  }

  void _dismissAutoNextDialog() {
    _autoNextTimer?.cancel();
    setState(() {
      _showAutoNextDialog = false;
    });
  }

  void _goToNextChapter() {
    if (_nextChapter != null) {
      _saveProgress();
      context.pushReplacementNamed('reader', extra: _nextChapter);
    }
  }

  void _goToPreviousChapter() {
    if (_previousChapter != null) {
      _saveProgress();
      context.pushReplacementNamed('reader', extra: _previousChapter);
    }
  }

  void _showChapterList() {
    final dir = Directory(p.dirname(widget.chapter.filePath));
    final pdfs = <FileSystemEntity>[];
    if (dir.existsSync()) {
      pdfs.addAll(dir.listSync().where((f) =>
          f is File && p.extension(f.path).toLowerCase() == '.pdf'));
    }
    pdfs.sort((a, b) => p.basenameWithoutExtension(a.path)
        .toLowerCase()
        .compareTo(p.basenameWithoutExtension(b.path).toLowerCase()));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Semua File',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Symbols.close, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: pdfs.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada file PDF ditemukan',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: pdfs.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: AppColors.outlineVariant,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final file = pdfs[index] as File;
                        final fileName = p.basenameWithoutExtension(file.path);
                        final isCurrent = file.path == widget.chapter.filePath;
                        final matchingChapter = _siblingChapters.where(
                            (c) => c.filePath == file.path).firstOrNull;
                        return ListTile(
                          dense: true,
                          selected: isCurrent,
                          selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          title: Text(
                            matchingChapter?.name ?? fileName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                              color: isCurrent ? AppColors.primary : AppColors.onSurface,
                            ),
                          ),
                          subtitle: !isCurrent && matchingChapter != null
                              ? Text(
                                  matchingChapter.name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          trailing: isCurrent
                              ? const Icon(Symbols.check, size: 18, color: AppColors.primary)
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            if (!isCurrent && matchingChapter != null) {
                              _saveProgress();
                              context.pushReplacementNamed('reader', extra: matchingChapter);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    final settings = ref.read(settingsProvider);
    double brightness = settings.readingBrightness;
    double overlay = settings.darkOverlay;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reader Settings',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'SETTINGS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Brightness',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: AppRadius.radiusLg,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.light_mode, color: AppColors.outline, size: 20),
                    Expanded(
                      child: Slider(
                        value: brightness,
                        min: 0.1,
                        max: 1.0,
                        onChanged: (value) {
                          setSheetState(() => brightness = value);
                          ref.read(settingsProvider.notifier).setReadingBrightness(value);
                        },
                      ),
                    ),
                    const Icon(Icons.light_mode, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Render Quality',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: AppRadius.radiusLg,
                ),
                child: Column(
                  children: RenderScale.values.map((scale) {
                    final isSelected = scale == settings.renderScale;
                    return ListTile(
                      dense: true,
                      leading: Radio<RenderScale>(
                        value: scale,
                        groupValue: settings.renderScale,
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(settingsProvider.notifier).setRenderScale(value);
                            setSheetState(() {});
                          }
                        },
                        activeColor: AppColors.primary,
                      ),
                      title: Text(
                        scale.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Display',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SettingsToggle(
                icon: Icons.nightlight,
                title: 'Night Filter',
                subtitle: 'Warmer tint for reading',
                value: overlay > 0,
                onChanged: (value) {
                  setSheetState(() => overlay = value ? 0.3 : 0);
                  ref.read(settingsProvider.notifier).setDarkOverlay(value ? 0.3 : 0);
                },
              ),
              _SettingsToggle(
                icon: Icons.stay_current_portrait,
                title: 'Keep Screen On',
                subtitle: 'Prevent sleep while reading',
                value: settings.keepScreenOn,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setKeepScreenOn(value);
                },
              ),
              _SettingsToggle(
                icon: Icons.skip_next,
                title: 'Auto Continue',
                subtitle: 'Auto next chapter',
                value: settings.autoContinue,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setAutoContinue(value);
                },
              ),
              _SettingsToggle(
                icon: Icons.swap_horiz,
                title: 'Reading Direction',
                subtitle: settings.readingDirection == ReadingDirection.leftToRight 
                    ? 'Left to Right' 
                    : 'Right to Left',
                value: settings.readingDirection == ReadingDirection.rightToLeft,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setReadingDirection(
                    value ? ReadingDirection.rightToLeft : ReadingDirection.leftToRight
                  );
                },
              ),
              _SettingsToggle(
                icon: Icons.rotate_right,
                title: 'Orientation',
                subtitle: _getOrientationLabel(settings.orientationMode),
                value: settings.orientationMode != OrientationMode.portrait,
                onChanged: (value) {
                  final modes = [OrientationMode.portrait, OrientationMode.landscape, OrientationMode.auto];
                  final currentIndex = modes.indexOf(settings.orientationMode);
                  final nextIndex = (currentIndex + 1) % modes.length;
                  ref.read(settingsProvider.notifier).setOrientationMode(modes[nextIndex]);
                  _applyOrientation();
                },
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    ).then((_) {
      ref.read(settingsProvider.notifier).setReadingBrightness(brightness);
      ref.read(settingsProvider.notifier).setDarkOverlay(overlay);
    });
  }

  String _getOrientationLabel(OrientationMode mode) {
    switch (mode) {
      case OrientationMode.auto:
        return 'Auto';
      case OrientationMode.portrait:
        return 'Portrait';
      case OrientationMode.landscape:
        return 'Landscape';
    }
  }

  Widget _buildPageView() {
    return _buildVerticalScrollMode();
  }

  Widget _buildVerticalScrollMode() {
    return ListView.builder(
      controller: _verticalScrollController,
      physics: const ClampingScrollPhysics(),
      itemCount: _renderer.totalPages,
      itemBuilder: (context, index) {
        return _ProgressivePageImage(
          pageIndex: index,
          renderer: _renderer,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF060E20),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Symbols.error, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal memuat PDF',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Coba Lagi',
                      icon: Icons.refresh,
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _isLoading = true;
                        });
                        _initRenderer();
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            )
          else if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else
            Stack(
              children: [
                GestureDetector(
                  onTap: _toggleControls,
                  behavior: HitTestBehavior.translucent,
                  child: _buildPageView(),
                ),
                if (settings.darkOverlay > 0)
                  IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: settings.darkOverlay),
                    ),
                  ),
                if (settings.readingBrightness < 1.0)
                  IgnorePointer(
                    child: Container(
                      color: Colors.white.withValues(alpha: 1.0 - settings.readingBrightness),
                    ),
                  ),
              ],
            ),

          if (_showAutoNextDialog && _nextChapter != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chapter selesai!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Beralih ke "${_nextChapter!.name}" dalam 5 detik...',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: _dismissAutoNextDialog,
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () {
                            _autoNextTimer?.cancel();
                            setState(() {
                              _showAutoNextDialog = false;
                            });
                            _goToNextChapter();
                          },
                          child: const Text('Sekarang'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: AppSpacing.sm,
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest.withValues(alpha: 0.8),
                      border: const Border(
                        top: BorderSide(
                          color: AppColors.glassBorderSubtle,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Symbols.navigate_before),
                          onPressed: _hasPreviousChapter ? _goToPreviousChapter : null,
                          color: _hasPreviousChapter
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                          tooltip: 'File Sebelumnya',
                        ),
                        IconButton(
                          icon: const Icon(Symbols.menu),
                          onPressed: _showChapterList,
                          color: AppColors.onSurface,
                          tooltip: 'Semua File',
                        ),
                        IconButton(
                          icon: const Icon(Symbols.settings),
                          onPressed: _showSettingsSheet,
                          color: AppColors.onSurface,
                          tooltip: 'Pengaturan',
                        ),
                        IconButton(
                          icon: const Icon(Symbols.navigate_next),
                          onPressed: _hasNextChapter ? _goToNextChapter : null,
                          color: _hasNextChapter
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                          tooltip: 'File Berikutnya',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressivePageImage extends StatefulWidget {
  const _ProgressivePageImage({
    required this.pageIndex,
    required this.renderer,
  });

  final int pageIndex;
  final PdfRenderer renderer;

  @override
  State<_ProgressivePageImage> createState() => _ProgressivePageImageState();
}

class _ProgressivePageImageState extends State<_ProgressivePageImage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ui.Image? _thumbnail;
  ui.Image? _lowRes;
  ui.Image? _highRes;
  int _currentPhase = 0; // 0=thumb, 1=low, 2=high

  @override
  void initState() {
    super.initState();
    _loadProgressive();
  }

  @override
  void dispose() {
    _thumbnail?.dispose();
    _lowRes?.dispose();
    _highRes?.dispose();
    super.dispose();
  }

  Future<void> _loadProgressive() async {
    if (!mounted) return;

    final rawThumb = await widget.renderer.getPageImage(widget.pageIndex, quality: RenderQuality.thumbnail);
    final thumb = rawThumb?.clone();
    if (mounted) {
      setState(() {
        _thumbnail = thumb;
        _currentPhase = 0;
      });
    }

    final rawLow = await widget.renderer.getPageImage(widget.pageIndex, quality: RenderQuality.lowRes);
    final low = rawLow?.clone();
    if (mounted) {
      setState(() {
        _lowRes = low;
        _currentPhase = 1;
      });
    }

    final rawHigh = await widget.renderer.getPageImage(widget.pageIndex, quality: RenderQuality.highRes);
    final high = rawHigh?.clone();
    if (mounted) {
      setState(() {
        _highRes = high;
        _currentPhase = 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final screenW = MediaQuery.of(context).size.width;

    Widget currentImage;
    if (_currentPhase == 2 && _highRes != null) {
      currentImage = _buildImage(_highRes!, screenW);
    } else if (_currentPhase >= 1 && _lowRes != null) {
      currentImage = _buildImage(_lowRes!, screenW);
    } else if (_thumbnail != null) {
      currentImage = _buildBlurredThumbnail(_thumbnail!, screenW);
    } else {
      return SizedBox(
        width: screenW,
        height: 200,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey(_currentPhase),
        child: currentImage,
      ),
    );
  }

  Widget _buildImage(ui.Image image, double screenW) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final displayH = imgH * (screenW / imgW);
    return SizedBox(
      width: screenW,
      height: displayH,
      child: RawImage(
        image: image,
        width: screenW,
        height: displayH,
        fit: BoxFit.fill,
      ),
    );
  }

  Widget _buildBlurredThumbnail(ui.Image image, double screenW) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final displayH = imgH * (screenW / imgW);
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: SizedBox(
        width: screenW,
        height: displayH,
        child: RawImage(
          image: image,
          width: screenW,
          height: displayH,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.low,
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: AppRadius.radiusMd,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}