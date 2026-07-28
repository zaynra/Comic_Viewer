import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';

import '../../domain/entities/thumbnail.dart';
import '../../domain/repositories/thumbnail_repository.dart';

class ThumbnailService {
  const ThumbnailService(this._thumbnailRepository);

  final ThumbnailRepository _thumbnailRepository;

  static const _coverExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
  static const _coverNames = ['cover', 'folder', 'thumb', 'poster'];
  static const int _thumbnailWidth = 600;

  Future<Thumbnail?> getThumbnail(int seriesId, String seriesPath) async {
    final existing = await _thumbnailRepository.getThumbnailBySeriesId(seriesId);
    if (existing != null && await File(existing.filePath).exists()) {
      return existing;
    }

    final customCover = _findCustomCover(seriesPath);
    if (customCover != null) {
      final thumbnail = Thumbnail(
        id: existing?.id ?? 0,
        seriesId: seriesId,
        source: 'custom',
        filePath: customCover,
        createdAt: DateTime.now(),
      );
      await _thumbnailRepository.saveThumbnail(thumbnail);
      return thumbnail;
    }

    if (existing == null) {
      final generated = await _generateThumbnail(seriesId, seriesPath);
      if (generated != null) {
        await _thumbnailRepository.saveThumbnail(generated);
        return generated;
      }
    }

    return existing;
  }

  Future<Thumbnail?> regenerateThumbnail(int seriesId, String seriesPath) async {
    await deleteThumbnail(seriesId);
    return _generateThumbnail(seriesId, seriesPath);
  }

  Future<Thumbnail?> setCustomCover(int seriesId, String seriesPath, String imagePath) async {
    await deleteThumbnail(seriesId);

    final thumbnail = Thumbnail(
      id: 0,
      seriesId: seriesId,
      source: 'custom',
      filePath: imagePath,
      createdAt: DateTime.now(),
    );
    await _thumbnailRepository.saveThumbnail(thumbnail);
    return thumbnail;
  }

  String? _findCustomCover(String seriesPath) {
    final dir = Directory(seriesPath);
    if (!dir.existsSync()) return null;

    for (final file in dir.listSync()) {
      if (file is File) {
        final fileName = p.basename(file.path).toLowerCase();
        final ext = p.extension(fileName);

        if (_coverExtensions.contains(ext)) {
          final nameWithoutExt = p.basenameWithoutExtension(fileName);
          if (_coverNames.contains(nameWithoutExt) ||
              nameWithoutExt.startsWith('cover') ||
              nameWithoutExt.startsWith('thumb')) {
            return file.path;
          }
        }
      }
    }

    return null;
  }

  Future<Thumbnail?> _generateThumbnail(int seriesId, String seriesPath) async {
    final pdfPath = _findFirstPdf(seriesPath);
    if (pdfPath == null) return null;

    try {
      final document = await PdfDocument.openFile(pdfPath);
      if (document.pagesCount > 0) {
        final page = await document.getPage(1);

        final scale = _thumbnailWidth / page.width;
        final renderWidth = _thumbnailWidth.toDouble();
        final renderHeight = (page.height * scale).roundToDouble();

        final pageImage = await page.render(
          width: renderWidth,
          height: renderHeight,
          format: PdfPageImageFormat.png,
        );
        await page.close();
        await document.close();

        if (pageImage != null) {
          final thumbnailDir = Directory(p.join(seriesPath, '.thumbnails'));
          if (!thumbnailDir.existsSync()) {
            await thumbnailDir.create(recursive: true);
          }

          final thumbnailPath = p.join(thumbnailDir.path, 'thumb_$seriesId.png');
          final file = File(thumbnailPath);
          await file.writeAsBytes(pageImage.bytes);

          return Thumbnail(
            id: 0,
            seriesId: seriesId,
            source: 'generated',
            filePath: thumbnailPath,
            createdAt: DateTime.now(),
          );
        }
      }
      await document.close();
    } catch (_) {}

    return null;
  }

  String? _findFirstPdf(String seriesPath) {
    final dir = Directory(seriesPath);
    if (!dir.existsSync()) return null;

    final pdfs = <String>[];
    for (final entity in dir.listSync()) {
      if (entity is File && p.extension(entity.path).toLowerCase() == '.pdf') {
        pdfs.add(entity.path);
      }
    }

    if (pdfs.isEmpty) return null;

    pdfs.sort((a, b) => _compareNatural(a, b));
    return pdfs.first;
  }

  int _compareNatural(String a, String b) {
    final nameA = p.basenameWithoutExtension(a).toLowerCase();
    final nameB = p.basenameWithoutExtension(b).toLowerCase();

    final regex = RegExp(r'(\d+)');
    final matchesA = regex.allMatches(nameA).toList();
    final matchesB = regex.allMatches(nameB).toList();

    if (matchesA.isNotEmpty && matchesB.isNotEmpty) {
      final numA = int.tryParse(matchesA.first.group(0)!) ?? 0;
      final numB = int.tryParse(matchesB.first.group(0)!) ?? 0;
      if (numA != numB) return numA.compareTo(numB);
    }

    return nameA.compareTo(nameB);
  }

  Future<void> deleteThumbnail(int seriesId) async {
    final existing = await _thumbnailRepository.getThumbnailBySeriesId(seriesId);
    if (existing != null) {
      final file = File(existing.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await _thumbnailRepository.deleteThumbnail(seriesId);
    }
  }

  Future<void> refreshThumbnail(int seriesId, String seriesPath) async {
    await deleteThumbnail(seriesId);
    await getThumbnail(seriesId, seriesPath);
  }

  Future<String?> getVaultThumbnail(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final thumbDir = Directory(p.join(p.dirname(filePath), '.vault_thumbnails'));
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }

    final thumbName = 'thumb_${p.basenameWithoutExtension(filePath)}.png';
    final thumbPath = p.join(thumbDir.path, thumbName);

    if (await File(thumbPath).exists()) return thumbPath;

    try {
      final document = await PdfDocument.openFile(filePath);
      if (document.pagesCount > 0) {
        final page = await document.getPage(1);
        final scale = _thumbnailWidth / page.width;
        final renderWidth = _thumbnailWidth.toDouble();
        final renderHeight = (page.height * scale).roundToDouble();

        final pageImage = await page.render(
          width: renderWidth,
          height: renderHeight,
          format: PdfPageImageFormat.png,
        );
        await page.close();
        await document.close();

        if (pageImage != null) {
          final thumbFile = File(thumbPath);
          await thumbFile.writeAsBytes(pageImage.bytes);
          return thumbPath;
        }
      }
      await document.close();
    } catch (_) {}

    return null;
  }
}