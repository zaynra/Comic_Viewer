import '../entities/chapter.dart';

abstract class ChaptersRepository {
  Future<List<Chapter>> getChaptersBySeriesId(int seriesId);
  Future<Chapter?> getChapterById(int id);
  Future<Chapter?> getChapterByFilePath(String filePath);
  Future<int> insertChapter(Chapter chapter);
  Future<void> updateChapter(Chapter chapter);
  Future<void> deleteChapter(int id);
  Future<void> deleteChaptersBySeriesId(int seriesId);
  Future<void> upsertChapter(Chapter chapter);
}
