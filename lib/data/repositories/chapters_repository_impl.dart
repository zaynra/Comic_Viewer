import '../../domain/entities/chapter.dart';
import '../../domain/repositories/chapters_repository.dart';
import '../databases/app_database.dart';

class ChaptersRepositoryImpl implements ChaptersRepository {
  final AppDatabase _db = AppDatabase.instance;

  @override
  Future<List<Chapter>> getChaptersBySeriesId(int seriesId) async {
    final db = await _db.database;
    final maps = await db.query(
      'chapters',
      where: 'series_id = ?',
      whereArgs: [seriesId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((map) => Chapter.fromMap(map)).toList();
  }

  @override
  Future<Chapter?> getChapterById(int id) async {
    final db = await _db.database;
    final maps = await db.query('chapters', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Chapter.fromMap(maps.first);
  }

  @override
  Future<Chapter?> getChapterByFilePath(String filePath) async {
    final db = await _db.database;
    final maps = await db.query(
      'chapters',
      where: 'file_path = ?',
      whereArgs: [filePath],
    );
    if (maps.isEmpty) return null;
    return Chapter.fromMap(maps.first);
  }

  @override
  Future<int> insertChapter(Chapter chapter) async {
    final db = await _db.database;
    return await db.insert('chapters', chapter.toMap()..remove('id'));
  }

  @override
  Future<void> updateChapter(Chapter chapter) async {
    final db = await _db.database;
    await db.update('chapters', chapter.toMap(), where: 'id = ?', whereArgs: [chapter.id]);
  }

  @override
  Future<void> deleteChapter(int id) async {
    final db = await _db.database;
    await db.delete('chapters', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteChaptersBySeriesId(int seriesId) async {
    final db = await _db.database;
    await db.delete('chapters', where: 'series_id = ?', whereArgs: [seriesId]);
  }

  @override
  Future<void> deleteOrphanedChapters() async {
    final db = await _db.database;
    await db.rawDelete(
      'DELETE FROM chapters WHERE series_id NOT IN (SELECT id FROM series)'
    );
  }

  @override
  Future<void> upsertChapter(Chapter chapter) async {
    final existing = await getChapterByFilePath(chapter.filePath);
    if (existing != null) {
      await updateChapter(chapter.copyWith(id: existing.id));
    } else {
      await insertChapter(chapter);
    }
  }
}
