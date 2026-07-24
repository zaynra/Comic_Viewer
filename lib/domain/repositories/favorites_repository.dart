import '../entities/series.dart';

abstract class FavoritesRepository {
  Future<List<Series>> getFavoriteSeries();
  Future<bool> isFavorite(int seriesId);
  Future<void> addFavorite(int seriesId);
  Future<void> removeFavorite(int seriesId);
  Future<void> toggleFavorite(int seriesId);
}
