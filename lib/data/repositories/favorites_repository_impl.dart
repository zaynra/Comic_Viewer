import '../../domain/entities/series.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../databases/app_database.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final AppDatabase _db = AppDatabase.instance;

  @override
  Future<List<Series>> getFavoriteSeries() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM series s
      INNER JOIN favorites f ON s.id = f.series_id
      ORDER BY f.created_at DESC
    ''');
    return maps.map((map) => Series.fromMap(map)).toList();
  }

  @override
  Future<bool> isFavorite(int seriesId) async {
    final db = await _db.database;
    final maps = await db.query(
      'favorites',
      where: 'series_id = ?',
      whereArgs: [seriesId],
    );
    return maps.isNotEmpty;
  }

  @override
  Future<void> addFavorite(int seriesId) async {
    final db = await _db.database;
    await db.insert('favorites', {
      'series_id': seriesId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> removeFavorite(int seriesId) async {
    final db = await _db.database;
    await db.delete(
      'favorites',
      where: 'series_id = ?',
      whereArgs: [seriesId],
    );
  }

  @override
  Future<void> toggleFavorite(int seriesId) async {
    final isFav = await isFavorite(seriesId);
    if (isFav) {
      await removeFavorite(seriesId);
    } else {
      await addFavorite(seriesId);
    }
  }
}
