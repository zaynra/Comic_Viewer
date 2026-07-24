import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/library_folder.dart';
import '../../domain/repositories/library_folder_repository.dart';

class LibraryFolderRepositoryImpl implements LibraryFolderRepository {
  LibraryFolderRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _pathKey = 'library_folder_path';
  static const _pickedAtKey = 'library_folder_picked_at';

  @override
  Future<LibraryFolder?> getSavedFolder() async {
    final path = _prefs.getString(_pathKey);
    if (path == null) return null;

    final pickedAtMillis = _prefs.getInt(_pickedAtKey);
    return LibraryFolder(
      path: path,
      pickedAt: pickedAtMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(pickedAtMillis)
          : DateTime.now(),
    );
  }

  @override
  Future<void> saveFolder(String path) async {
    await _prefs.setString(_pathKey, path);
    await _prefs.setInt(_pickedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<void> clearFolder() async {
    await _prefs.remove(_pathKey);
    await _prefs.remove(_pickedAtKey);
  }
}
