import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class ChapterMetadata {
  const ChapterMetadata({
    this.title,
    this.volume,
    this.chapter,
    this.language,
    this.pages,
  });

  final String? title;
  final String? volume;
  final String? chapter;
  final String? language;
  final int? pages;

  factory ChapterMetadata.fromJson(Map<String, dynamic> json) {
    return ChapterMetadata(
      title: json['title'] as String?,
      volume: json['volume'] as String?,
      chapter: json['chapter'] as String?,
      language: json['language'] as String?,
      pages: json['pages'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (volume != null) 'volume': volume,
      if (chapter != null) 'chapter': chapter,
      if (language != null) 'language': language,
      if (pages != null) 'pages': pages,
    };
  }
}

class SeriesMetadata {
  const SeriesMetadata({
    this.title,
    this.author,
    this.artist,
    this.description,
    this.genres,
    this.language,
    this.year,
  });

  final String? title;
  final String? author;
  final String? artist;
  final String? description;
  final List<String>? genres;
  final String? language;
  final int? year;

  factory SeriesMetadata.fromJson(Map<String, dynamic> json) {
    return SeriesMetadata(
      title: json['title'] as String?,
      author: json['author'] as String?,
      artist: json['artist'] as String?,
      description: json['description'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.cast<String>(),
      language: json['language'] as String?,
      year: json['year'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (artist != null) 'artist': artist,
      if (description != null) 'description': description,
      if (genres != null) 'genres': genres,
      if (language != null) 'language': language,
      if (year != null) 'year': year,
    };
  }
}

class MetadataParser {
  static Future<SeriesMetadata?> parseSeriesMetadata(String seriesPath) async {
    final metadataFile = File(p.join(seriesPath, 'metadata.json'));
    if (!await metadataFile.exists()) return null;

    try {
      final content = await metadataFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return SeriesMetadata.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Future<ChapterMetadata?> parseChapterMetadata(String chapterPath) async {
    final dir = p.dirname(chapterPath);
    final baseName = p.basenameWithoutExtension(chapterPath);
    final metadataFile = File(p.join(dir, '$baseName.json'));

    if (!await metadataFile.exists()) return null;

    try {
      final content = await metadataFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return ChapterMetadata.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static String getDisplayName(String filePath, ChapterMetadata? metadata) {
    if (metadata?.title != null && metadata!.title!.isNotEmpty) {
      return metadata.title!;
    }

    final baseName = p.basenameWithoutExtension(filePath);
    final regex = RegExp(r'Chapter[_\s]*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(baseName);

    if (match != null) {
      final num = match.group(1);
      if (num != null) {
        return 'Chapter $num';
      }
    }

    return baseName;
  }

  static int parseSortOrder(String filePath, ChapterMetadata? metadata) {
    if (metadata?.chapter != null) {
      final chapterNum = int.tryParse(metadata!.chapter!);
      if (chapterNum != null) return chapterNum;
    }

    final baseName = p.basenameWithoutExtension(filePath);
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(baseName);

    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 0;
    }

    return 0;
  }
}
