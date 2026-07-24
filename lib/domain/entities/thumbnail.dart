class Thumbnail {
  const Thumbnail({
    required this.id,
    required this.seriesId,
    required this.source,
    required this.filePath,
    required this.createdAt,
  });

  final int id;
  final int seriesId;
  final String source;
  final String filePath;
  final DateTime createdAt;

  bool get isCustom => source == 'custom';
  bool get isGenerated => source == 'generated';

  Thumbnail copyWith({
    int? id,
    int? seriesId,
    String? source,
    String? filePath,
    DateTime? createdAt,
  }) {
    return Thumbnail(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      source: source ?? this.source,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'series_id': seriesId,
      'source': source,
      'file_path': filePath,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Thumbnail.fromMap(Map<String, dynamic> map) {
    return Thumbnail(
      id: map['id'] as int,
      seriesId: map['series_id'] as int,
      source: map['source'] as String,
      filePath: map['file_path'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
