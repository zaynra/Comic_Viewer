import '../entities/reading_progress.dart';

abstract class ReadingProgressRepository {
  Future<ReadingProgress?> getProgressByChapterId(int chapterId);
  Future<void> saveProgress(ReadingProgress progress);
  Future<void> deleteProgress(int chapterId);
  Future<List<ReadingProgress>> getRecentProgress({int limit = 10});
}
