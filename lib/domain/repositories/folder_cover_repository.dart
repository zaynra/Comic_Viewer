abstract class FolderCoverRepository {
  Future<String?> getCover(String folderPath);
  Future<void> setCover(String folderPath, String coverPath);
  Future<void> deleteCover(String folderPath);
  Future<Map<String, String>> getAllCovers();
}
