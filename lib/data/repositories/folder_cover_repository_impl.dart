import '../../domain/repositories/folder_cover_repository.dart';
import '../databases/app_database.dart';

class FolderCoverRepositoryImpl implements FolderCoverRepository {
  final AppDatabase _db = AppDatabase.instance;

  @override
  Future<String?> getCover(String folderPath) async {
    final db = await _db.database;
    final maps = await db.query(
      'folder_covers',
      where: 'folder_path = ?',
      whereArgs: [folderPath],
    );
    if (maps.isEmpty) return null;
    return maps.first['cover_path'] as String;
  }

  @override
  Future<void> setCover(String folderPath, String coverPath) async {
    final db = await _db.database;
    final existing = await getCover(folderPath);

    if (existing != null) {
      await db.update(
        'folder_covers',
        {
          'cover_path': coverPath,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'folder_path = ?',
        whereArgs: [folderPath],
      );
    } else {
      await db.insert('folder_covers', {
        'folder_path': folderPath,
        'cover_path': coverPath,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  @override
  Future<void> deleteCover(String folderPath) async {
    final db = await _db.database;
    await db.delete(
      'folder_covers',
      where: 'folder_path = ?',
      whereArgs: [folderPath],
    );
  }

  @override
  Future<Map<String, String>> getAllCovers() async {
    final db = await _db.database;
    final maps = await db.query('folder_covers');
    final result = <String, String>{};
    for (final map in maps) {
      result[map['folder_path'] as String] = map['cover_path'] as String;
    }
    return result;
  }
}
