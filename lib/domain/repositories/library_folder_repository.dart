import '../entities/library_folder.dart';

/// Abstraction for reading/writing which folder the user selected
/// as their comic library root. Implemented in the data layer —
/// presentation and application layers only depend on this interface.
abstract class LibraryFolderRepository {
  Future<LibraryFolder?> getSavedFolder();
  Future<void> saveFolder(String path);
  Future<void> clearFolder();
}
