import '../entities/series.dart';

abstract class RecentRepository {
  Future<List<Series>> getRecentSeries({int limit = 10});
  Future<void> addRecent(int seriesId);
  Future<void> clearRecent();
}
