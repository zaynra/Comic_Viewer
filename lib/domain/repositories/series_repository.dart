import '../entities/series.dart';

abstract class SeriesRepository {
  Future<List<Series>> getAllSeries();
  Future<Series?> getSeriesById(int id);
  Future<Series?> getSeriesByPath(String path);
  Future<int> insertSeries(Series series);
  Future<void> updateSeries(Series series);
  Future<void> deleteSeries(int id);
  Future<void> upsertSeries(Series series);
}
