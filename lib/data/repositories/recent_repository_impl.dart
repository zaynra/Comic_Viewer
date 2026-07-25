import '../../domain/entities/series.dart';
import '../../domain/repositories/recent_repository.dart';
import '../databases/app_database.dart';

class RecentRepositoryImpl implements RecentRepository {
  final AppDatabase _db = AppDatabase.instance;

  @override
  Future<List<Series>> getRecentSeries({int limit = 10}) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM series s
      INNER JOIN recent r ON s.id = r.series_id
      WHERE s.is_vaulted = 0
      ORDER BY r.last_opened_at DESC
      LIMIT ?
    ''', [limit]);
    return maps.map((map) => Series.fromMap(map)).toList();
  }

  @override
  Future<void> addRecent(int seriesId) async {
    final db = await _db.database;

    await db.delete(
      'recent',
      where: 'series_id = ?',
      whereArgs: [seriesId],
    );

    await db.insert('recent', {
      'series_id': seriesId,
      'last_opened_at': DateTime.now().millisecondsSinceEpoch,
    });

    await db.rawDelete('''
      DELETE FROM recent WHERE id NOT IN (
        SELECT id FROM recent ORDER BY last_opened_at DESC LIMIT 50
      )
    ''');
  }

  @override
  Future<void> clearRecent() async {
    final db = await _db.database;
    await db.delete('recent');
  }
}
