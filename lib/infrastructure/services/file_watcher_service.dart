import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../../domain/entities/chapter.dart';
import '../../domain/entities/series.dart';
import '../../domain/repositories/chapters_repository.dart';
import '../../domain/repositories/series_repository.dart';

class FileWatcherService {
  FileWatcherService(this._seriesRepository, this._chaptersRepository);

  final SeriesRepository _seriesRepository;
  final ChaptersRepository _chaptersRepository;

  DirectoryWatcher? _watcher;
  StreamSubscription<WatchEvent>? _subscription;
  Timer? _debounceTimer;

  final _changes = <String, ChangeType>{};
  bool _isProcessing = false;

  StreamController<WatchResult>? _resultController;
  Stream<WatchResult>? get onChanges => _resultController?.stream;

  void startWatching(String folderPath) {
    stopWatching();

    _resultController = StreamController<WatchResult>.broadcast();
    _watcher = DirectoryWatcher(folderPath);

    _subscription = _watcher!.events.listen((event) {
      final ext = p.extension(event.path).toLowerCase();
      if (ext != '.pdf' && ext != '.jpg' && ext != '.jpeg' && ext != '.png') {
        return;
      }

      _changes[event.path] = event.type;
      _debounceChanges();
    });
  }

  void _debounceChanges() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _processChanges);
  }

  Future<void> _processChanges() async {
    if (_isProcessing || _changes.isEmpty) return;
    _isProcessing = true;

    final changes = Map<String, ChangeType>.from(_changes);
    _changes.clear();

    final added = <String>[];
    final removed = <String>[];
    final modified = <String>[];

    for (final entry in changes.entries) {
      switch (entry.value) {
        case ChangeType.ADD:
          added.add(entry.key);
          break;
        case ChangeType.REMOVE:
          removed.add(entry.key);
          break;
        case ChangeType.MODIFY:
          modified.add(entry.key);
          break;
      }
    }

    int seriesChanges = 0;
    int chapterChanges = 0;

    for (final filePath in added) {
      if (p.extension(filePath).toLowerCase() == '.pdf') {
        await _addChapter(filePath);
        chapterChanges++;
      }
    }

    for (final filePath in removed) {
      await _removeChapter(filePath);
      chapterChanges++;
    }

    for (final filePath in modified) {
      if (p.extension(filePath).toLowerCase() == '.pdf') {
        await _updateChapter(filePath);
        chapterChanges++;
      }
    }

    await _cleanupEmptySeries();
    seriesChanges = await _countSeriesChanges();

    _isProcessing = false;

    _resultController?.add(WatchResult(
      addedCount: added.length,
      removedCount: removed.length,
      modifiedCount: modified.length,
      seriesChanges: seriesChanges,
      chapterChanges: chapterChanges,
    ));
  }

  Future<void> _addChapter(String filePath) async {
    final dirPath = p.dirname(filePath);

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

    final existing = await _chaptersRepository.getChapterByFilePath(filePath);
    if (existing == null) {
      final chapterName = p.basenameWithoutExtension(filePath);
      final allChapters = await _chaptersRepository.getChaptersBySeriesId(series.id);

      final chapter = Chapter(
        id: 0,
        seriesId: series.id,
        name: chapterName,
        filePath: filePath,
        sortOrder: allChapters.length + 1,
      );
      await _chaptersRepository.insertChapter(chapter);
    }
  }

  Future<void> _removeChapter(String filePath) async {
    final existing = await _chaptersRepository.getChapterByFilePath(filePath);
    if (existing != null) {
      await _chaptersRepository.deleteChapter(existing.id);
    }
  }

  Future<void> _updateChapter(String filePath) async {
    final existing = await _chaptersRepository.getChapterByFilePath(filePath);
    if (existing != null) {
      final chapterName = p.basenameWithoutExtension(filePath);
      if (existing.name != chapterName) {
        await _chaptersRepository.updateChapter(
          existing.copyWith(name: chapterName),
        );
      }
    } else {
      await _addChapter(filePath);
    }
  }

  Future<void> _cleanupEmptySeries() async {
    final allSeries = await _seriesRepository.getAllSeries();
    for (final series in allSeries) {
      final chapters = await _chaptersRepository.getChaptersBySeriesId(series.id);
      if (chapters.isEmpty) {
        await _seriesRepository.deleteSeries(series.id);
      }
    }
  }

  Future<int> _countSeriesChanges() async {
    return 0;
  }

  void stopWatching() {
    _subscription?.cancel();
    _subscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _watcher = null;
    _changes.clear();
    _resultController?.close();
    _resultController = null;
  }

  void dispose() {
    stopWatching();
  }
}

class WatchResult {
  const WatchResult({
    required this.addedCount,
    required this.removedCount,
    required this.modifiedCount,
    required this.seriesChanges,
    required this.chapterChanges,
  });

  final int addedCount;
  final int removedCount;
  final int modifiedCount;
  final int seriesChanges;
  final int chapterChanges;

  bool get hasChanges => addedCount > 0 || removedCount > 0 || modifiedCount > 0;
}
