class Chapter {
  const Chapter({
    required this.id,
    required this.seriesId,
    required this.name,
    required this.filePath,
    required this.sortOrder,
    this.totalPages = 0,
    this.currentPage = 0,
    this.isRead = false,
  });

  final int id;
  final int seriesId;
  final String name;
  final String filePath;
  final int sortOrder;
  final int totalPages;
  final int currentPage;
  final bool isRead;

  double get progress =>
      totalPages > 0 ? currentPage / totalPages : 0.0;

  Chapter copyWith({
    int? id,
    int? seriesId,
    String? name,
    String? filePath,
    int? sortOrder,
    int? totalPages,
    int? currentPage,
    bool? isRead,
  }) {
    return Chapter(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      sortOrder: sortOrder ?? this.sortOrder,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'series_id': seriesId,
      'name': name,
      'file_path': filePath,
      'sort_order': sortOrder,
      'total_pages': totalPages,
      'current_page': currentPage,
      'is_read': isRead ? 1 : 0,
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] as int,
      seriesId: map['series_id'] as int,
      name: map['name'] as String,
      filePath: map['file_path'] as String,
      sortOrder: map['sort_order'] as int,
      totalPages: map['total_pages'] as int? ?? 0,
      currentPage: map['current_page'] as int? ?? 0,
      isRead: (map['is_read'] as int? ?? 0) == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chapter &&
          other.id == id &&
          other.seriesId == seriesId &&
          other.filePath == filePath);

  @override
  int get hashCode => Object.hash(id, filePath);
}
