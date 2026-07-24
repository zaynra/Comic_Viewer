import '../../domain/entities/library_folder.dart';
import '../../domain/repositories/library_folder_repository.dart';
import '../../infrastructure/services/folder_picker_service.dart';

/// Opens the OS folder picker and, if the user picks something,
/// persists it as the library root.
class PickLibraryFolder {
  const PickLibraryFolder(this._pickerService, this._repository);

  final FolderPickerService _pickerService;
  final LibraryFolderRepository _repository;

  Future<LibraryFolder?> call() async {
    final path = await _pickerService.pickFolder();
    if (path == null) return null;

    await _repository.saveFolder(path);
    return LibraryFolder(path: path, pickedAt: DateTime.now());
  }
}

/// Returns the previously saved library folder, if any.
class GetSavedLibraryFolder {
  const GetSavedLibraryFolder(this._repository);

  final LibraryFolderRepository _repository;

  Future<LibraryFolder?> call() => _repository.getSavedFolder();
}
