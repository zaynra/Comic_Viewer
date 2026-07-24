import '../entities/thumbnail.dart';

abstract class ThumbnailRepository {
  Future<Thumbnail?> getThumbnailBySeriesId(int seriesId);
  Future<void> saveThumbnail(Thumbnail thumbnail);
  Future<void> deleteThumbnail(int seriesId);
  Future<List<Thumbnail>> getAllThumbnails();
}
