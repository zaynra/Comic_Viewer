import '../../domain/entities/thumbnail.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../databases/app_database.dart';

class ThumbnailRepositoryImpl implements ThumbnailRepository {
  final AppDatabase _db = AppDatabase.instance;

  @override
  Future<Thumbnail?> getThumbnailBySeriesId(int seriesId) async {
    final db = await _db.database;
    final maps = await db.query(
      'thumbnails',
      where: 'series_id = ?',
      whereArgs: [seriesId],
    );
    if (maps.isEmpty) return null;
    return Thumbnail.fromMap(maps.first);
  }

  @override
  Future<void> saveThumbnail(Thumbnail thumbnail) async {
    final db = await _db.database;
    final existing = await getThumbnailBySeriesId(thumbnail.seriesId);

    if (existing != null) {
      await db.update(
        'thumbnails',
        thumbnail.copyWith(id: existing.id).toMap(),
        where: 'series_id = ?',
        whereArgs: [thumbnail.seriesId],
      );
    } else {
      await db.insert('thumbnails', thumbnail.toMap()..remove('id'));
    }
  }

  @override
  Future<void> deleteThumbnail(int seriesId) async {
    final db = await _db.database;
    await db.delete(
      'thumbnails',
      where: 'series_id = ?',
      whereArgs: [seriesId],
    );
  }

  @override
  Future<List<Thumbnail>> getAllThumbnails() async {
    final db = await _db.database;
    final maps = await db.query('thumbnails');
    return maps.map((map) => Thumbnail.fromMap(map)).toList();
  }
}
