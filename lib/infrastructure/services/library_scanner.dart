import 'dart:io';
import 'dart:developer' as developer;

import 'package:path/path.dart' as p;

import '../../domain/entities/chapter.dart';
import '../../domain/entities/series.dart';
import '../../domain/repositories/chapters_repository.dart';
import '../../domain/repositories/series_repository.dart';
import 'metadata_parser.dart';

void debugPrint(String message) {
  developer.log(message, name: 'LibraryScanner');
}

class LibraryScanner {
  const LibraryScanner(this._seriesRepository, this._chaptersRepository);

  final SeriesRepository _seriesRepository;
  final ChaptersRepository _chaptersRepository;

  Future<ScanResult> scanFolder(String folderPath) async {
    debugPrint('[SCANNER] scanFolder called with: $folderPath');
    final rootDir = Directory(folderPath);
    
    final exists = await rootDir.exists();
    debugPrint('[SCANNER] Directory exists: $exists');
    
    if (!exists) {
      debugPrint('[SCANNER] Directory does NOT exist, returning error');
      return ScanResult.error('Folder tidak ditemukan: $folderPath');
    }

    int seriesCount = 0;
    int chapterCount = 0;

    debugPrint('[SCANNER] Listing directory contents (recursive: false)...');
    final entities = rootDir.listSync(recursive: false);
    debugPrint('[SCANNER] Found ${entities.length} entities in root');

    for (final entity in entities) {
      debugPrint('[SCANNER] Entity: ${entity.path} (${entity.runtimeType})');
      if (entity is Directory) {
        debugPrint('[SCANNER] Scanning subfolder: ${entity.path}');
        final result = await _scanSeriesFolder(entity);
        if (result != null) {
          seriesCount++;
          chapterCount += result;
          debugPrint('[SCANNER] Subfolder ${entity.path} yielded $result chapters');
        } else {
          debugPrint('[SCANNER] Subfolder ${entity.path} yielded no chapters');
        }
      } else if (entity is File && _isPdf(entity.path)) {
        debugPrint('[SCANNER] Found standalone PDF: ${entity.path}');
        await _addStandalonePdf(entity);
        seriesCount++;
        chapterCount++;
      }
    }

    debugPrint('[SCANNER] Scan complete: $seriesCount series, $chapterCount chapters');
    return ScanResult.success(seriesCount, chapterCount);
  }

  Future<int?> _scanSeriesFolder(Directory seriesDir) async {
    debugPrint('[SCANNER] _scanSeriesFolder: ${seriesDir.path}');
    final pdfFiles = _findPdfFiles(seriesDir);
    debugPrint('[SCANNER] Found ${pdfFiles.length} PDFs in ${seriesDir.path}');

    if (pdfFiles.isEmpty) {
      debugPrint('[SCANNER] No PDFs found, returning null');
      return null;
    }

    final seriesName = p.basename(seriesDir.path);
    debugPrint('[SCANNER] Series name: $seriesName');
    
    final metadata = await MetadataParser.parseSeriesMetadata(seriesDir.path);
    debugPrint('[SCANNER] Metadata loaded: ${metadata != null}');

    var series = await _seriesRepository.getSeriesByPath(seriesDir.path);
    debugPrint('[SCANNER] Existing series found: ${series != null}');
    if (series == null) {
      series = Series(
        id: 0,
        name: metadata?.title ?? seriesName,
        path: seriesDir.path,
        author: metadata?.author,
        description: metadata?.description,
        genres: metadata?.genres,
        createdAt: DateTime.now(),
      );
      final id = await _seriesRepository.insertSeries(series);
      series = series.copyWith(id: id);
    } else {
      final updatedSeries = series.copyWith(
        name: metadata?.title ?? series.name,
        author: metadata?.author ?? series.author,
        description: metadata?.description ?? series.description,
        genres: metadata?.genres ?? series.genres,
      );
      if (updatedSeries != series) {
        await _seriesRepository.updateSeries(updatedSeries);
        series = updatedSeries;
      }
    }

    final sortedChapters = _naturalSort(pdfFiles);

    int order = 0;
    for (final filePath in sortedChapters) {
      order++;
      final chapterMetadata = await MetadataParser.parseChapterMetadata(filePath);
      final chapterName = MetadataParser.getDisplayName(filePath, chapterMetadata);
      final chapterOrder = MetadataParser.parseSortOrder(filePath, chapterMetadata);

      var chapter = await _chaptersRepository.getChapterByFilePath(filePath);
      if (chapter == null) {
        chapter = Chapter(
          id: 0,
          seriesId: series.id,
          name: chapterName,
          filePath: filePath,
          sortOrder: chapterOrder > 0 ? chapterOrder : order,
        );
        await _chaptersRepository.insertChapter(chapter);
      } else {
        final updatedChapter = chapter.copyWith(
          name: chapterName,
          sortOrder: chapterOrder > 0 ? chapterOrder : order,
          seriesId: series.id,
        );
        if (updatedChapter != chapter) {
          await _chaptersRepository.updateChapter(updatedChapter);
        }
      }
    }

    return sortedChapters.length;
  }

  Future<void> _addStandalonePdf(File pdfFile) async {
    final dirPath = p.dirname(pdfFile.path);

    var series = await _seriesRepository.getSeriesByPath(dirPath);
    if (series == null) {
      series = Series(
        id: 0,
        name: p.basename(dirPath),
        path: dirPath,
        createdAt: DateTime.now(),
      );
      final id = await _seriesRepository.insertSeries(series);
      series = series.copyWith(id: id);
    }

    final chapterMetadata = await MetadataParser.parseChapterMetadata(pdfFile.path);
    final chapterName = MetadataParser.getDisplayName(pdfFile.path, chapterMetadata);

    var chapter = await _chaptersRepository.getChapterByFilePath(pdfFile.path);
    if (chapter == null) {
      chapter = Chapter(
        id: 0,
        seriesId: series.id,
        name: chapterName,
        filePath: pdfFile.path,
        sortOrder: 1,
      );
      await _chaptersRepository.insertChapter(chapter);
    } else {
      final updated = chapter.copyWith(seriesId: series.id, name: chapterName);
      if (updated != chapter) {
        await _chaptersRepository.updateChapter(updated);
      }
    }
  }

  List<String> _findPdfFiles(Directory dir) {
    debugPrint('[SCANNER] _findPdfFiles: ${dir.path}');
    final pdfs = <String>[];
    try {
      final entities = dir.listSync(recursive: false);
      for (final entity in entities) {
        if (entity is File && _isPdf(entity.path)) {
          pdfs.add(entity.path);
        } else if (entity is Directory) {
          pdfs.addAll(_findPdfFiles(entity));
        }
      }
    } catch (e) {
      debugPrint('[SCANNER] ERROR scanning ${dir.path}: $e');
    }
    return pdfs;
  }

  bool _isPdf(String path) {
    return p.extension(path).toLowerCase() == '.pdf';
  }

  List<String> _naturalSort(List<String> paths) {
    final sorted = List<String>.from(paths);
    sorted.sort((a, b) => _compareNatural(a, b));
    return sorted;
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
}

class ScanResult {
  const ScanResult._({required this.isSuccess, this.seriesCount = 0, this.chapterCount = 0, this.errorMessage});

  factory ScanResult.success(int seriesCount, int chapterCount) {
    return ScanResult._(isSuccess: true, seriesCount: seriesCount, chapterCount: chapterCount);
  }

  factory ScanResult.error(String message) {
    return ScanResult._(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final int seriesCount;
  final int chapterCount;
  final String? errorMessage;
}
