import '../../domain/entities/series.dart';
import '../../domain/repositories/series_repository.dart';
import '../databases/app_database.dart';

class SeriesRepositoryImpl implements SeriesRepository {
  final AppDatabase _db = AppDatabase.instance;

  @override
  Future<List<Series>> getAllSeries() async {
    final db = await _db.database;
    final maps = await db.query('series',
        where: 'is_vaulted = 0', orderBy: 'name ASC');
    return maps.map((map) => Series.fromMap(map)).toList();
  }

  @override
  Future<Series?> getSeriesById(int id) async {
    final db = await _db.database;
    final maps = await db.query('series', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Series.fromMap(maps.first);
  }

  @override
  Future<Series?> getSeriesByPath(String path) async {
    final db = await _db.database;
    final maps = await db.query('series', where: 'path = ?', whereArgs: [path]);
    if (maps.isEmpty) return null;
    return Series.fromMap(maps.first);
  }

  @override
  Future<List<Series>> getVaultedSeries() async {
    final db = await _db.database;
    final maps = await db.query('series',
        where: 'is_vaulted = 1', orderBy: 'name ASC');
    return maps.map((map) => Series.fromMap(map)).toList();
  }

  @override
  Future<int> insertSeries(Series series) async {
    final db = await _db.database;
    return await db.insert('series', series.toMap()..remove('id'));
  }

  @override
  Future<void> updateSeries(Series series) async {
    final db = await _db.database;
    await db.update('series', series.toMap(), where: 'id = ?', whereArgs: [series.id]);
  }

  @override
  Future<void> deleteSeries(int id) async {
    final db = await _db.database;
    await db.delete('series', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> upsertSeries(Series series) async {
    final existing = await getSeriesByPath(series.path);
    if (existing != null) {
      await updateSeries(series.copyWith(id: existing.id));
    } else {
      await insertSeries(series);
    }
  }

  @override
  Future<void> toggleVault(int seriesId) async {
    final db = await _db.database;
    final maps = await db.query('series',
        where: 'id = ?', whereArgs: [seriesId]);
    if (maps.isEmpty) return;
    final series = Series.fromMap(maps.first);
    final newState = series.isVaulted ? 0 : 1;
    await db.rawUpdate(
        'UPDATE series SET is_vaulted = ? WHERE id = ?',
        [newState, seriesId]);
  }
}
