class Bookmark {
  const Bookmark({
    required this.id,
    required this.chapterId,
    required this.page,
    required this.createdAt,
    this.note,
  });

  final int id;
  final int chapterId;
  final int page;
  final DateTime createdAt;
  final String? note;

  Bookmark copyWith({
    int? id,
    int? chapterId,
    int? page,
    DateTime? createdAt,
    String? note,
  }) {
    return Bookmark(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      page: page ?? this.page,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapter_id': chapterId,
      'page': page,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int,
      chapterId: map['chapter_id'] as int,
      page: map['page'] as int,
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
