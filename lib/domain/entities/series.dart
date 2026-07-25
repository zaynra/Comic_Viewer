class Series {
  const Series({
    required this.id,
    required this.name,
    required this.path,
    this.coverPath,
    this.author,
    this.description,
    this.genres,
    this.isVaulted = false,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String path;
  final String? coverPath;
  final String? author;
  final String? description;
  final List<String>? genres;
  final bool isVaulted;
  final DateTime createdAt;

  Series copyWith({
    int? id,
    String? name,
    String? path,
    String? coverPath,
    String? author,
    String? description,
    List<String>? genres,
    bool? isVaulted,
    DateTime? createdAt,
  }) {
    return Series(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      coverPath: coverPath ?? this.coverPath,
      author: author ?? this.author,
      description: description ?? this.description,
      genres: genres ?? this.genres,
      isVaulted: isVaulted ?? this.isVaulted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'cover_path': coverPath,
      'author': author,
      'description': description,
      'genres': genres?.join(','),
      'is_vaulted': isVaulted ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Series.fromMap(Map<String, dynamic> map) {
    return Series(
      id: map['id'] as int,
      name: map['name'] as String,
      path: map['path'] as String,
      coverPath: map['cover_path'] as String?,
      author: map['author'] as String?,
      description: map['description'] as String?,
      genres: (map['genres'] as String?)?.split(',').where((g) => g.isNotEmpty).toList(),
      isVaulted: (map['is_vaulted'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Series && other.id == id && other.path == path);

  @override
  int get hashCode => Object.hash(id, path);
}
