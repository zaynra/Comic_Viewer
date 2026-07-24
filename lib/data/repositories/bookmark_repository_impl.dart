import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../databases/app_database.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  final AppDatabase _db = AppDatabase.instance;

  @override
  Future<List<Bookmark>> getBookmarksByChapterId(int chapterId) async {
    final db = await _db.database;
    final maps = await db.query(
      'bookmarks',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      orderBy: 'page ASC',
    );
    return maps.map((map) => Bookmark.fromMap(map)).toList();
  }

  @override
  Future<Bookmark?> getBookmarkAtPage(int chapterId, int page) async {
    final db = await _db.database;
    final maps = await db.query(
      'bookmarks',
      where: 'chapter_id = ? AND page = ?',
      whereArgs: [chapterId, page],
    );
    if (maps.isEmpty) return null;
    return Bookmark.fromMap(maps.first);
  }

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    final db = await _db.database;
    await db.insert('bookmarks', bookmark.toMap()..remove('id'));
  }

  @override
  Future<void> removeBookmark(int id) async {
    final db = await _db.database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<bool> isBookmarked(int chapterId, int page) async {
    final bookmark = await getBookmarkAtPage(chapterId, page);
    return bookmark != null;
  }
}
