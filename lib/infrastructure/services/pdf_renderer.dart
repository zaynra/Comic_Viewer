import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';

class PdfLoadException implements Exception {
  PdfLoadException(this.message);
  final String message;

  @override
  String toString() => message;
}

enum RenderQuality {
  thumbnail,
  lowRes,
  highRes,
}

class _RenderParams {
  const _RenderParams({
    required this.filePath,
    required this.pageIndex,
    required this.scale,
  });

  final String filePath;
  final int pageIndex;
  final double scale;
}

Future<PdfPageImage?> _renderLowResIsolate(_RenderParams params) async {
  try {
    final document = await PdfDocument.openFile(params.filePath);
    final page = await document.getPage(params.pageIndex + 1);

    final renderWidth = (page.width * params.scale).roundToDouble();
    final renderHeight = (page.height * params.scale).roundToDouble();

    final pageImage = await page.render(
      width: renderWidth,
      height: renderHeight,
      format: PdfPageImageFormat.png,
    );

    await page.close();
    await document.close();

    return pageImage;
  } catch (e) {
    debugPrint('[PDF] Isolate error rendering page ${params.pageIndex}: $e');
    return null;
  }
}

class PdfRenderer {
  PdfRenderer(this._filePath, {double renderScale = 1.0}) : _renderScale = renderScale;

  final String _filePath;
  double _renderScale;
  PdfDocument? _document;
  int _currentPageIndex = 0;
  int _totalPages = 0;

  static const int _maxThumbnailCache = 20;
  static const int _maxLowResCache = 15;
  static const int _maxHighResCache = 8;

  bool _memoryWarning = false;

  final LinkedHashMap<int, PdfPageImage> _rawCacheThumbnail = LinkedHashMap();
  final LinkedHashMap<int, PdfPageImage> _rawCacheLowRes = LinkedHashMap();
  final LinkedHashMap<int, PdfPageImage> _rawCacheHighRes = LinkedHashMap();
  final LinkedHashMap<String, ui.Image> _imageCache = LinkedHashMap();

  String _cacheKey(int index, RenderQuality quality) => '${index}_${quality.index}';

  int get currentPage => _currentPageIndex;
  int get totalPages => _totalPages;
  double get renderScale => _renderScale;
  bool get hasDocument => _document != null;
  bool get canGoPrevious => _currentPageIndex > 0;
  bool get canGoNext => _currentPageIndex < _totalPages - 1;

  Future<void> open() async {
    try {
      final sw = Stopwatch()..start();
      _document = await PdfDocument.openFile(_filePath);
      _totalPages = _document!.pagesCount;
      _currentPageIndex = 0;
      _clearAllCaches();
      debugPrint('[PDF] Opened ${_filePath.split('/').last} in ${sw.elapsedMilliseconds}ms ($_totalPages pages)');
    } catch (e) {
      throw PdfLoadException('Gagal memuat PDF: ${e.toString()}');
    }
  }

  void _clearAllCaches() {
    _disposeImageCache();
    _rawCacheThumbnail.clear();
    _rawCacheLowRes.clear();
    _rawCacheHighRes.clear();
  }

  void _disposeImageCache() {
    for (final img in _imageCache.values) {
      img.dispose();
    }
    _imageCache.clear();
  }

  void setRenderScale(double scale) {
    if ((_renderScale - scale).abs() < 0.01) return;
    _renderScale = scale;
    _clearHighResCache();
    debugPrint('[PDF] Render scale changed to ${_renderScale}x');
  }

  void _clearHighResCache() {
    _rawCacheHighRes.clear();
    final keys = _imageCache.keys.where((k) => k.endsWith('_${RenderQuality.highRes.index}')).toList();
    for (final k in keys) {
      final img = _imageCache.remove(k);
      img?.dispose();
    }
  }

  Future<PdfPageImage?> _renderRawPage(int index, RenderQuality quality) async {
    if (_document == null || index < 0 || index >= _totalPages) return null;

    final cache = _getCacheForQuality(quality);
    if (cache.containsKey(index)) {
      return cache[index];
    }

    final scale = _getScaleForQuality(quality);

    try {
      final page = await _document!.getPage(index + 1);

      final renderWidth = (page.width * scale).roundToDouble();
      final renderHeight = (page.height * scale).roundToDouble();

      final pageImage = await page.render(
        width: renderWidth,
        height: renderHeight,
        format: PdfPageImageFormat.png,
      );

      await page.close();

      if (pageImage != null) {
        _putCache(quality, index, pageImage);
      }

      return pageImage;
    } catch (e) {
      debugPrint('[PDF] Error rendering page $index at ${quality.name}: $e');
      return null;
    }
  }

  Future<PdfPageImage?> _renderLowResBackground(int index) async {
    try {
      return await compute(_renderLowResIsolate, _RenderParams(
        filePath: _filePath,
        pageIndex: index,
        scale: 1.0,
      ));
    } catch (e) {
      debugPrint('[PDF] Isolate failed for page $index, falling back to main thread: $e');
      return _renderRawPage(index, RenderQuality.lowRes);
    }
  }

  LinkedHashMap<int, PdfPageImage> _getCacheForQuality(RenderQuality quality) {
    switch (quality) {
      case RenderQuality.thumbnail:
        return _rawCacheThumbnail;
      case RenderQuality.lowRes:
        return _rawCacheLowRes;
      case RenderQuality.highRes:
        return _rawCacheHighRes;
    }
  }

  double _getScaleForQuality(RenderQuality quality) {
    switch (quality) {
      case RenderQuality.thumbnail:
        return 0.5;
      case RenderQuality.lowRes:
        return 1.0;
      case RenderQuality.highRes:
        return _renderScale;
    }
  }

  int _getMaxCacheSize(RenderQuality quality) {
    switch (quality) {
      case RenderQuality.thumbnail:
        return _maxThumbnailCache;
      case RenderQuality.lowRes:
        return _maxLowResCache;
      case RenderQuality.highRes:
        return _maxHighResCache;
    }
  }

  void _putCache(RenderQuality quality, int index, PdfPageImage image) {
    final cache = _getCacheForQuality(quality);
    final maxSize = _getMaxCacheSize(quality);

    if (cache.length >= maxSize) {
      final oldest = cache.keys.first;
      cache.remove(oldest);
    }
    cache[index] = image;
  }

  Future<ui.Image?> _convertToImage(int index, RenderQuality quality) async {
    final key = _cacheKey(index, quality);
    if (_imageCache.containsKey(key)) {
      return _imageCache[key];
    }

    final pageImage = await _renderRawPage(index, quality);
    if (pageImage == null) return null;

    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(pageImage.bytes);
      final image = await ui.instantiateImageCodecWithSize(buffer).then((codec) async {
        final frame = await codec.getNextFrame();
        return frame.image;
      });

      final maxForQuality = quality == RenderQuality.highRes ? _maxHighResCache : _maxLowResCache;
      if (_imageCache.length >= maxForQuality) {
        final oldest = _imageCache.keys.first;
        final oldImg = _imageCache.remove(oldest);
        oldImg?.dispose();
      }
      _imageCache[key] = image;

      return image;
    } catch (e) {
      debugPrint('[PDF] Error converting page $index: $e');
      return null;
    }
  }

  Future<ui.Image?> getPageImage(int index, {RenderQuality quality = RenderQuality.highRes}) async {
    final sw = Stopwatch()..start();
    final image = await _convertToImage(index, quality);
    debugPrint('[PDF] Page ${index + 1} (${quality.name}) loaded in ${sw.elapsedMilliseconds}ms');
    return image;
  }

  Future<void> prefetchRange(int start, int end, RenderQuality quality) async {
    start = start.clamp(0, _totalPages - 1);
    end = end.clamp(0, _totalPages - 1);

    final futures = <Future<void>>[];
    for (int i = start; i <= end; i++) {
      if (quality == RenderQuality.lowRes && !_rawCacheLowRes.containsKey(i)) {
        futures.add(_renderLowResBackground(i).then((img) {
          if (img != null) _putCache(RenderQuality.lowRes, i, img);
        }));
      } else if (!_getCacheForQuality(quality).containsKey(i)) {
        futures.add(_renderRawPage(i, quality).then((img) {
          if (img != null) _putCache(quality, i, img);
        }));
      }
    }
    await Future.wait(futures);
  }

  Future<void> prefetchHighRes(int index) async {
    final key = _cacheKey(index, RenderQuality.highRes);
    if (index >= 0 && index < _totalPages && !_imageCache.containsKey(key)) {
      unawaited(_convertToImage(index, RenderQuality.highRes));
    }
  }

  Future<bool> goToPage(int index) async {
    if (index < 0 || index >= _totalPages || _document == null) return false;
    _currentPageIndex = index;
    return true;
  }

  Future<bool> nextPage() async {
    return goToPage(_currentPageIndex + 1);
  }

  Future<bool> previousPage() async {
    return goToPage(_currentPageIndex - 1);
  }

  Map<String, int> get debugStats => {
    'totalCached': _imageCache.length,
    'thumb': _rawCacheThumbnail.length,
    'lowRes': _rawCacheLowRes.length,
    'highRes': _rawCacheHighRes.length,
    'images': _imageCache.length,
    'maxThumb': _maxThumbnailCache,
    'maxLow': _maxLowResCache,
    'maxHigh': _maxHighResCache,
  };

  void checkMemoryPressure() {}


  void disposeCache() {
    _disposeImageCache();
    _rawCacheThumbnail.clear();
    _rawCacheLowRes.clear();
    _rawCacheHighRes.clear();
  }

  Future<void> close() async {
    disposeCache();
    await _document?.close();
    _document = null;
  }
}