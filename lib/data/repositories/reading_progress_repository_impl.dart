import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../databases/app_database.dart';

class ReadingProgressRepositoryImpl implements ReadingProgressRepository {
  final AppDatabase _db = AppDatabase.instance;

  @override
  Future<ReadingProgress?> getProgressByChapterId(int chapterId) async {
    final db = await _db.database;
    final maps = await db.query(
      'reading_progress',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
    if (maps.isEmpty) return null;
    return ReadingProgress.fromMap(maps.first);
  }

  @override
  Future<void> saveProgress(ReadingProgress progress) async {
    final db = await _db.database;
    final existing = await getProgressByChapterId(progress.chapterId);

    if (existing != null) {
      await db.update(
        'reading_progress',
        progress.copyWith(id: existing.id).toMap(),
        where: 'chapter_id = ?',
        whereArgs: [progress.chapterId],
      );
    } else {
      await db.insert('reading_progress', progress.toMap()..remove('id'));
    }
  }

  @override
  Future<void> deleteProgress(int chapterId) async {
    final db = await _db.database;
    await db.delete(
      'reading_progress',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
  }

  @override
  Future<List<ReadingProgress>> getRecentProgress({int limit = 10}) async {
    final db = await _db.database;
    final maps = await db.query(
      'reading_progress',
      orderBy: 'last_opened_at DESC',
      limit: limit,
    );
    return maps.map((map) => ReadingProgress.fromMap(map)).toList();
  }
}
