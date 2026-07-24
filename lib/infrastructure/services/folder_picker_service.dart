import 'package:file_picker/file_picker.dart';

/// Thin wrapper around the platform folder picker. On Android this goes
/// through the Storage Access Framework (SAF) via `file_picker`, so no
/// runtime storage permission is required for this specific action.
///
/// Isolated here so the rest of the app never depends on `file_picker`
/// directly — if the picker package changes later, only this file changes.
class FolderPickerService {
  const FolderPickerService();

  /// Returns the picked directory path, or null if the user cancelled.
  Future<String?> pickFolder() {
    try {
      return FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih folder komik',
      );
    } catch (e) {
      throw FolderPickerException('Gagal membuka folder picker: $e');
    }
  }
}

class FolderPickerException implements Exception {
  FolderPickerException(this.message);
  final String message;

  @override
  String toString() => message;
}
