import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'comic_viewer.db';
  static const _dbVersion = 8;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE reading_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          chapter_id INTEGER NOT NULL UNIQUE,
          current_page INTEGER DEFAULT 0,
          zoom_level REAL DEFAULT 1.0,
          last_opened_at INTEGER NOT NULL,
          FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE thumbnails (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          series_id INTEGER NOT NULL UNIQUE,
          source TEXT NOT NULL,
          file_path TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (series_id) REFERENCES series(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE favorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          series_id INTEGER NOT NULL UNIQUE,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (series_id) REFERENCES series(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE recent (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          series_id INTEGER NOT NULL,
          last_opened_at INTEGER NOT NULL,
          FOREIGN KEY (series_id) REFERENCES series(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_recent_last_opened ON recent(last_opened_at DESC)');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE series ADD COLUMN author TEXT');
      await db.execute('ALTER TABLE series ADD COLUMN description TEXT');
      await db.execute('ALTER TABLE series ADD COLUMN genres TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE bookmarks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          chapter_id INTEGER NOT NULL,
          page INTEGER NOT NULL,
          note TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE,
          UNIQUE(chapter_id, page)
        )
      ''');
    await db.execute('CREATE INDEX idx_bookmarks_chapter ON bookmarks(chapter_id)');

    await db.execute('''
      CREATE TABLE folder_covers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_path TEXT NOT NULL UNIQUE,
        cover_path TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE series ADD COLUMN is_vaulted INTEGER DEFAULT 0');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE folder_covers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          folder_path TEXT NOT NULL UNIQUE,
          cover_path TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE series (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT NOT NULL UNIQUE,
        cover_path TEXT,
        author TEXT,
        description TEXT,
        genres TEXT,
        is_vaulted INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        series_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL UNIQUE,
        sort_order INTEGER NOT NULL,
        total_pages INTEGER DEFAULT 0,
        current_page INTEGER DEFAULT 0,
        is_read INTEGER DEFAULT 0,
        FOREIGN KEY (series_id) REFERENCES series(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE library_index (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_path TEXT NOT NULL UNIQUE,
        last_scanned_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reading_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER NOT NULL UNIQUE,
        current_page INTEGER DEFAULT 0,
        zoom_level REAL DEFAULT 1.0,
        last_opened_at INTEGER NOT NULL,
        FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE thumbnails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        series_id INTEGER NOT NULL UNIQUE,
        source TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (series_id) REFERENCES series(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        series_id INTEGER NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (series_id) REFERENCES series(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recent (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        series_id INTEGER NOT NULL,
        last_opened_at INTEGER NOT NULL,
        FOREIGN KEY (series_id) REFERENCES series(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_recent_last_opened ON recent(last_opened_at DESC)');

    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER NOT NULL,
        page INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE,
        UNIQUE(chapter_id, page)
      )
    ''');

    await db.execute('CREATE INDEX idx_bookmarks_chapter ON bookmarks(chapter_id)');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
