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

class PdfRenderer {
  PdfRenderer(this._filePath);

  final String _filePath;
  PdfDocument? _document;
  int _currentPageIndex = 0;
  int _totalPages = 0;

  final LinkedHashMap<int, PdfPageImage> _rawCache = LinkedHashMap();
  final LinkedHashMap<int, ui.Image> _imageCache = LinkedHashMap();
  static const int _cacheSize = 6;
  static const int _disposeRange = 8;

  int get currentPage => _currentPageIndex;
  int get totalPages => _totalPages;
  bool get hasDocument => _document != null;
  bool get canGoPrevious => _currentPageIndex > 0;
  bool get canGoNext => _currentPageIndex < _totalPages - 1;

  Future<void> open() async {
    try {
      final sw = Stopwatch()..start();
      _document = await PdfDocument.openFile(_filePath);
      _totalPages = _document!.pagesCount;
      _currentPageIndex = 0;
      _rawCache.clear();
      _imageCache.clear();
      debugPrint('[PDF] Opened ${_filePath.split('/').last} in ${sw.elapsedMilliseconds}ms ($_totalPages pages)');
    } catch (e) {
      throw PdfLoadException('Gagal memuat PDF: ${e.toString()}');
    }
  }

  void _disposeOffScreen(int current) {
    final keysToDispose = <int>[];
    for (final key in _imageCache.keys) {
      if ((key - current).abs() > _disposeRange) {
        keysToDispose.add(key);
      }
    }
    for (final key in keysToDispose) {
      final img = _imageCache.remove(key);
      img?.dispose();
      _rawCache.remove(key);
    }
    if (keysToDispose.isNotEmpty) {
      debugPrint('[PDF] Disposed ${keysToDispose.length} off-screen pages');
    }
  }

  Future<PdfPageImage?> _renderRawPage(int index) async {
    if (_document == null || index < 0 || index >= _totalPages) return null;

    if (_rawCache.containsKey(index)) {
      return _rawCache[index];
    }

    try {
      final page = await _document!.getPage(index + 1);

      final renderWidth = (page.width * 2.0).roundToDouble();
      final renderHeight = (page.height * 2.0).roundToDouble();

      final pageImage = await page.render(
        width: renderWidth,
        height: renderHeight,
        format: PdfPageImageFormat.png,
      );

      await page.close();

      if (pageImage != null) {
        if (_rawCache.length >= _cacheSize) {
          final oldest = _rawCache.keys.first;
          _rawCache.remove(oldest);
        }
        _rawCache[index] = pageImage;
      }

      return pageImage;
    } catch (e) {
      debugPrint('[PDF] Error rendering page $index: $e');
      return null;
    }
  }

  Future<ui.Image?> _convertToImage(int index) async {
    if (_imageCache.containsKey(index)) {
      return _imageCache[index];
    }

    final pageImage = await _renderRawPage(index);
    if (pageImage == null) return null;

    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(pageImage.bytes);
      final image = await ui.instantiateImageCodecWithSize(buffer).then((codec) async {
        final frame = await codec.getNextFrame();
        return frame.image;
      });

      if (_imageCache.length >= _cacheSize) {
        final oldest = _imageCache.keys.first;
        final oldImg = _imageCache.remove(oldest);
        oldImg?.dispose();
        _rawCache.remove(oldest);
      }
      _imageCache[index] = image;

      return image;
    } catch (e) {
      debugPrint('[PDF] Error converting page $index: $e');
      return null;
    }
  }

  Future<ui.Image?> getCurrentPageImage() async {
    final sw = Stopwatch()..start();
    final image = await _convertToImage(_currentPageIndex);
    debugPrint('[PDF] Page ${_currentPageIndex + 1} loaded in ${sw.elapsedMilliseconds}ms');

    _disposeOffScreen(_currentPageIndex);
    _prefetchNeighbors();

    return image;
  }

  Future<ui.Image?> getPageImage(int index) async {
    return _convertToImage(index);
  }

  void _prefetchNeighbors() {
    final neighbors = [_currentPageIndex - 1, _currentPageIndex + 1];
    for (final idx in neighbors) {
      if (idx >= 0 && idx < _totalPages && !_imageCache.containsKey(idx)) {
        unawaited(_convertToImage(idx));
      }
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

  void disposeCache() {
    for (final img in _imageCache.values) {
      img.dispose();
    }
    _imageCache.clear();
    _rawCache.clear();
  }

  Future<void> close() async {
    for (final img in _imageCache.values) {
      img.dispose();
    }
    _imageCache.clear();
    _rawCache.clear();
    await _document?.close();
    _document = null;
  }
}
