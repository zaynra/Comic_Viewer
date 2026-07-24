import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/data_providers.dart';
import '../../../domain/entities/bookmark.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/reading_progress.dart';
import '../../../infrastructure/services/pdf_renderer.dart';
import '../../settings/providers/settings_provider.dart';

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

  void _showBrightnessDialog() {
    final settings = ref.read(settingsProvider);
    double brightness = settings.readingBrightness;
    double overlay = settings.darkOverlay;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pengaturan Layar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Symbols.brightness_low, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: brightness,
                      min: 0.1,
                      max: 1.0,
                      onChanged: (value) {
                        setDialogState(() => brightness = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Symbols.dark_mode, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: overlay,
                      min: 0.0,
                      max: 0.8,
                      onChanged: (value) {
                        setDialogState(() => overlay = value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).setReadingBrightness(brightness);
                ref.read(settingsProvider.notifier).setDarkOverlay(overlay);
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFitModeDialog() {
    final settings = ref.read(settingsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mode Tampilan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FitMode.values.map((mode) {
            return RadioListTile<FitMode>(
              title: Text(mode.label),
              value: mode,
              groupValue: settings.fitMode,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setFitMode(value!);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showReadingModeDialog() {
    final settings = ref.read(settingsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mode Baca'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReadingMode.values.map((mode) {
            return RadioListTile<ReadingMode>(
              title: Text(mode.label),
              value: mode,
              groupValue: settings.readingMode,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setReadingMode(value!);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
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
      backgroundColor: Colors.black,
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
                    Text(
                      'Gagal memuat PDF',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _isLoading = true;
                        });
                        _initRenderer();
                      },
                      icon: const Icon(Symbols.refresh),
                      label: const Text('Coba Lagi'),
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

          if (_showAutoNextDialog && _nextChapter != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Card(
                color: AppColors.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chapter selesai!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Beralih ke "${_nextChapter!.name}" dalam 5 detik...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            ),

          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.onSurface,
                  title: Text(widget.chapter.name),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isBookmarked ? Symbols.bookmark : Symbols.bookmark_border,
                        color: _isBookmarked ? AppColors.primary : AppColors.onSurface,
                      ),
                      onPressed: _toggleBookmark,
                      tooltip: _isBookmarked ? 'Hapus Bookmark' : 'Bookmark',
                    ),
                    IconButton(
                      icon: const Icon(Symbols.brightness_medium),
                      onPressed: _showBrightnessDialog,
                      tooltip: 'Kecerahan',
                    ),
                    IconButton(
                      icon: const Icon(Symbols.fit_screen),
                      onPressed: _showFitModeDialog,
                      tooltip: 'Mode Tampilan',
                    ),
                    IconButton(
                      icon: const Icon(Symbols.menu_book),
                      onPressed: _showReadingModeDialog,
                      tooltip: 'Mode Baca',
                    ),
                  ],
                ),
              ),
            ),

          if (_showControls && settings.readingMode != ReadingMode.vertical)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Symbols.skip_previous, size: 20),
                            onPressed: _hasPreviousChapter ? _goToPreviousChapter : null,
                            color: AppColors.onSurface,
                            tooltip: _previousChapter?.name ?? 'File sebelumnya',
                          ),
                          IconButton(
                            icon: const Icon(Symbols.arrow_back_ios, size: 20),
                            onPressed: _renderer.canGoPrevious ? _previousPage : null,
                            color: AppColors.onSurface,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_renderer.currentPage + 1} / ${_renderer.totalPages}',
                                  style: const TextStyle(
                                    color: AppColors.onSurface,
                                    fontSize: 12,
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  ),
                                  child: Slider(
                                    value: _renderer.currentPage.toDouble(),
                                    min: 0,
                                    max: (_renderer.totalPages - 1).toDouble().clamp(1, double.infinity),
                                    onChanged: (value) {
                                      _goToPage(value.toInt());
                                      _startAutoHideTimer();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Symbols.arrow_forward_ios, size: 20),
                            onPressed: _renderer.canGoNext ? _nextPage : null,
                            color: AppColors.onSurface,
                          ),
                          IconButton(
                            icon: const Icon(Symbols.skip_next, size: 20),
                            onPressed: _hasNextChapter ? _goToNextChapter : null,
                            color: AppColors.onSurface,
                            tooltip: _nextChapter?.name ?? 'File berikutnya',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
