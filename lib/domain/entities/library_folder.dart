/// Represents the root folder the user picked as their comic library.
class LibraryFolder {
  const LibraryFolder({required this.path, required this.pickedAt});

  final String path;
  final DateTime pickedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryFolder && other.path == path);

  @override
  int get hashCode => path.hashCode;
}
