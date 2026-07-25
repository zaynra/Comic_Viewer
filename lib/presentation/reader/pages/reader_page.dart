import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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

class _ReaderPageState extends ConsumerState<ReaderPage> {
  late PdfRenderer _renderer;
  bool _isLoading = true;
  bool _isPageLoading = false;
  String? _error;
  bool _showControls = false;
  double _scale = 1.0;
  ReadingProgress? _savedProgress;
  List<Chapter> _siblingChapters = [];
  int _currentChapterIndex = 0;
  Timer? _autoNextTimer;
  bool _showAutoNextDialog = false;
  ui.Image? _currentImage;
  ui.Image? _nextImage;
  bool _isBookmarked = false;
  Bookmark? _currentBookmark;

  Timer? _hideControlsTimer;
  final ScrollController _verticalScrollController = ScrollController();
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _renderer = PdfRenderer(widget.chapter.filePath);
    _initRenderer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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

      _currentImage = await _renderer.getCurrentPageImage();
      await _checkBookmark();
      await _prefetchNext();

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

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    _hideControlsTimer?.cancel();
    _saveProgress();
    _renderer.disposeCache();
    _renderer.close();
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
    if (_renderer.hasDocument) {
      final progress = ReadingProgress(
        id: _savedProgress?.id ?? 0,
        chapterId: widget.chapter.id,
        currentPage: _renderer.currentPage,
        zoomLevel: _scale,
        lastOpenedAt: DateTime.now(),
      );
      await ref.read(readingProgressRepositoryProvider).saveProgress(progress);
    }
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

  Future<void> _toggleBookmark() async {
    final repo = ref.read(bookmarkRepositoryProvider);
    if (_isBookmarked && _currentBookmark != null) {
      await repo.removeBookmark(_currentBookmark!.id);
    } else {
      await repo.addBookmark(Bookmark(
        id: 0,
        chapterId: widget.chapter.id,
        page: _renderer.currentPage,
        createdAt: DateTime.now(),
      ));
    }
    await _checkBookmark();
  }

  Future<void> _prefetchNext() async {
    if (_renderer.canGoNext) {
      _nextImage = await _renderer.getPageImage(_renderer.currentPage + 1);
    } else {
      _nextImage = null;
    }
  }

  void _onTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    if (tapX < screenWidth / 3) {
      final settings = ref.read(settingsProvider);
      if (settings.readingDirection == ReadingDirection.rightToLeft) {
        _nextPage();
      } else {
        _previousPage();
      }
    } else if (tapX > screenWidth * 2 / 3) {
      final settings = ref.read(settingsProvider);
      if (settings.readingDirection == ReadingDirection.rightToLeft) {
        _previousPage();
      } else {
        _nextPage();
      }
    } else {
      _toggleControls();
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
      setState(() {
        _isPageLoading = true;
        _scale = 1.0;
        _transformationController.value = Matrix4.identity();
      });
      await _renderer.nextPage();
      _currentImage = _nextImage;
      _nextImage = null;
      _checkBookmark();
      _prefetchNext();
      setState(() {
        _isPageLoading = false;
      });
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
      setState(() {
        _isPageLoading = true;
        _scale = 1.0;
        _transformationController.value = Matrix4.identity();
      });
      await _renderer.previousPage();
      _currentImage = await _renderer.getCurrentPageImage();
      _checkBookmark();
      _prefetchNext();
      setState(() {
        _isPageLoading = false;
      });
    } else if (_hasPreviousChapter) {
      _goToPreviousChapter();
    }
  }

  Future<void> _goToPage(int page) async {
    setState(() {
      _isPageLoading = true;
      _scale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
    await _renderer.goToPage(page);
    _currentImage = await _renderer.getCurrentPageImage();
    _checkBookmark();
    _prefetchNext();
    setState(() {
      _isPageLoading = false;
    });
  }

  void _onDoubleTapDown(TapDownDetails details) {
    if (_scale > 1.0) {
      setState(() {
        _scale = 1.0;
        _transformationController.value = Matrix4.identity();
      });
    } else {
      setState(() {
        _scale = 2.0;
      });
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
              // Drag handle
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

              // Header
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

              // Brightness
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
                        },
                      ),
                    ),
                    const Icon(Icons.light_mode, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // View Mode
              const Text(
                'View Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.5,
                children: FitMode.values.map((mode) {
                  final isSelected = mode == settings.fitMode;
                  return GestureDetector(
                    onTap: () {
                      ref.read(settingsProvider.notifier).setFitMode(mode);
                      setSheetState(() {});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: AppRadius.radiusLg,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getFitModeIcon(mode),
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Scroll Mode
              const Text(
                'Scroll Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: AppRadius.radiusLg,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: ReadingMode.values.map((mode) {
                    final isSelected = mode == settings.readingMode;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(settingsProvider.notifier).setReadingMode(mode);
                          setSheetState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.surfaceContainer
                                : Colors.transparent,
                            borderRadius: AppRadius.radiusMd,
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getReadingModeIcon(mode),
                                size: 16,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                mode.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Display toggles
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
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                subtitle: 'Reduce eye strain',
                value: true,
                onChanged: (_) {},
              ),
              _SettingsToggle(
                icon: Icons.nightlight,
                title: 'Night Filter',
                subtitle: 'Warmer tint for reading',
                value: overlay > 0,
                onChanged: (value) {
                  setSheetState(() => overlay = value ? 0.3 : 0);
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

  IconData _getFitModeIcon(FitMode mode) {
    switch (mode) {
      case FitMode.fitWidth:
        return Icons.fit_screen;
      case FitMode.fitHeight:
        return Icons.height;
      case FitMode.fitScreen:
        return Icons.crop_free;
      case FitMode.original:
        return Icons.aspect_ratio;
    }
  }

  IconData _getReadingModeIcon(ReadingMode mode) {
    switch (mode) {
      case ReadingMode.vertical:
        return Icons.swap_vert;
      case ReadingMode.doublePage:
        return Icons.view_stream;
      case ReadingMode.single:
        return Icons.swap_horiz;
    }
  }

  Widget _buildPageView() {
    final settings = ref.watch(settingsProvider);

    if (settings.readingMode == ReadingMode.vertical) {
      return _buildVerticalScrollMode();
    }

    if (settings.readingMode == ReadingMode.doublePage) {
      return _buildDoublePageMode();
    }

    return _buildSinglePageMode();
  }

  Widget _buildSinglePageMode() {
    final settings = ref.watch(settingsProvider);

    return GestureDetector(
      onTapDown: _onTapDown,
      onDoubleTapDown: _onDoubleTapDown,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenW = constraints.maxWidth;
          final screenH = constraints.maxHeight;

          if (_currentImage == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final imgW = _currentImage!.width.toDouble();
          final imgH = _currentImage!.height.toDouble();

          double displayW;
          double displayH;

          switch (settings.fitMode) {
            case FitMode.fitScreen:
              final scaleW = screenW / imgW;
              final scaleH = screenH / imgH;
              final scale = scaleW < scaleH ? scaleW : scaleH;
              displayW = imgW * scale;
              displayH = imgH * scale;
              break;
            case FitMode.fitWidth:
              displayW = screenW;
              displayH = imgH * (screenW / imgW);
              break;
            case FitMode.fitHeight:
              displayH = screenH;
              displayW = imgW * (screenH / imgH);
              break;
            case FitMode.original:
              displayW = imgW;
              displayH = imgH;
              break;
          }

          return InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 5.0,
            onInteractionUpdate: (details) {
              setState(() {
                _scale = _transformationController.value.getMaxScaleOnAxis();
              });
            },
            child: SizedBox(
              width: screenW,
              height: screenH,
              child: Center(
                child: SizedBox(
                  width: displayW,
                  height: displayH,
                  child: RawImage(
                    image: _currentImage,
                    width: displayW,
                    height: displayH,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoublePageMode() {
    final settings = ref.watch(settingsProvider);

    return GestureDetector(
      onTapDown: _onTapDown,
      onDoubleTapDown: _onDoubleTapDown,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfW = constraints.maxWidth / 2;
          final screenH = constraints.maxHeight;

          return Row(
            children: [
              Expanded(
                child: _currentImage != null
                    ? _buildFittedPageHalf(_currentImage!, halfW, screenH, settings.fitMode)
                    : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _nextImage != null
                    ? _buildFittedPageHalf(_nextImage!, halfW, screenH, settings.fitMode)
                    : const SizedBox(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFittedPageHalf(ui.Image image, double maxW, double maxH, FitMode fitMode) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    double displayW;
    double displayH;

    switch (fitMode) {
      case FitMode.fitScreen:
        final scaleW = maxW / imgW;
        final scaleH = maxH / imgH;
        final scale = scaleW < scaleH ? scaleW : scaleH;
        displayW = imgW * scale;
        displayH = imgH * scale;
        break;
      case FitMode.fitWidth:
        displayW = maxW;
        displayH = imgH * (maxW / imgW);
        break;
      case FitMode.fitHeight:
        displayH = maxH;
        displayW = imgW * (maxH / imgH);
        break;
      case FitMode.original:
        displayW = imgW;
        displayH = imgH;
        break;
    }

    return Center(
      child: SizedBox(
        width: displayW,
        height: displayH,
        child: RawImage(
          image: image,
          width: displayW,
          height: displayH,
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  Widget _buildVerticalScrollMode() {
    return ListView.builder(
      controller: _verticalScrollController,
      physics: const ClampingScrollPhysics(),
      itemCount: _renderer.totalPages,
      itemBuilder: (context, index) {
        return FutureBuilder<ui.Image?>(
          future: _renderer.getPageImage(index),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final img = snapshot.data!;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final screenW = constraints.maxWidth;
                  final imgW = img.width.toDouble();
                  final imgH = img.height.toDouble();
                  final displayH = imgH * (screenW / imgW);
                  return SizedBox(
                    width: screenW,
                    height: displayH,
                    child: RawImage(
                      image: img,
                      width: screenW,
                      height: displayH,
                      fit: BoxFit.fill,
                    ),
                  );
                },
              );
            }
            return Container(
              height: 400,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: AppColors.primary),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                _buildPageView(),
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
                if (_isPageLoading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
              ],
            ),

          // Auto-next dialog
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

          // Top App Bar (Glassmorphism)
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest.withValues(alpha: 0.8),
                      border: const Border(
                        bottom: BorderSide(
                          color: AppColors.glassBorderSubtle,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.pop(),
                          color: AppColors.onSurface,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Row(
                            children: [
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
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  widget.chapter.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '${_renderer.currentPage + 1} / ${_renderer.totalPages}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {},
                          color: AppColors.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Controls (Glassmorphism)
          if (_showControls && settings.readingMode != ReadingMode.vertical)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: PageSlider(
                      currentPage: _renderer.currentPage + 1,
                      totalPages: _renderer.totalPages,
                      onChanged: (value) {
                        _goToPage(value.toInt() - 1);
                        _startAutoHideTimer();
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Bottom Nav
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.pill,
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
                            borderRadius: AppRadius.pill,
                            border: Border.all(
                              color: AppColors.glassBorder,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ReaderNavButton(
                                icon: Icons.skip_previous,
                                label: 'Prev',
                                onPressed: _hasPreviousChapter ? _goToPreviousChapter : null,
                              ),
                              _ReaderNavButton(
                                icon: Icons.skip_next,
                                label: 'Next',
                                onPressed: _hasNextChapter ? _goToNextChapter : null,
                              ),
                              _ReaderNavButton(
                                icon: Icons.settings,
                                label: 'Settings',
                                onPressed: _showSettingsSheet,
                              ),
                              _ReaderNavButton(
                                icon: Icons.more_horiz,
                                label: 'More',
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReaderNavButton extends StatelessWidget {
  const _ReaderNavButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          icon,
          color: onPressed != null ? AppColors.onSurfaceVariant : AppColors.outline,
          size: 24,
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
          ),
        ],
      ),
    );
  }
}
