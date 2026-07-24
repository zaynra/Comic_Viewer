import '../entities/bookmark.dart';

abstract class BookmarkRepository {
  Future<List<Bookmark>> getBookmarksByChapterId(int chapterId);
  Future<Bookmark?> getBookmarkAtPage(int chapterId, int page);
  Future<void> addBookmark(Bookmark bookmark);
  Future<void> removeBookmark(int id);
  Future<bool> isBookmarked(int chapterId, int page);
}
