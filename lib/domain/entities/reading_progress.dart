class ReadingProgress {
  const ReadingProgress({
    required this.id,
    required this.chapterId,
    required this.currentPage,
    this.zoomLevel = 1.0,
    required this.lastOpenedAt,
  });

  final int id;
  final int chapterId;
  final int currentPage;
  final double zoomLevel;
  final DateTime lastOpenedAt;

  ReadingProgress copyWith({
    int? id,
    int? chapterId,
    int? currentPage,
    double? zoomLevel,
    DateTime? lastOpenedAt,
  }) {
    return ReadingProgress(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      currentPage: currentPage ?? this.currentPage,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapter_id': chapterId,
      'current_page': currentPage,
      'zoom_level': zoomLevel,
      'last_opened_at': lastOpenedAt.millisecondsSinceEpoch,
    };
  }

  factory ReadingProgress.fromMap(Map<String, dynamic> map) {
    return ReadingProgress(
      id: map['id'] as int,
      chapterId: map['chapter_id'] as int,
      currentPage: map['current_page'] as int? ?? 0,
      zoomLevel: (map['zoom_level'] as num?)?.toDouble() ?? 1.0,
      lastOpenedAt: DateTime.fromMillisecondsSinceEpoch(map['last_opened_at'] as int),
    );
  }
}
