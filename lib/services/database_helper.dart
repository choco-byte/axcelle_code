import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'movie_app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE movies(
        id INTEGER PRIMARY KEY,
        title TEXT,
        overview TEXT,
        poster_path TEXT,
        vote_average REAL,
        release_date TEXT,
        is_showing INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE watchlist(
        id INTEGER PRIMARY KEY,
        title TEXT,
        poster_path TEXT
      )
    ''');
  }

  Future<void> cacheMovies(
    List<Map<String, dynamic>> movies,
    bool isNowPlaying,
  ) async {
    final db = await database;
    final batch = db.batch();
    await batch.commit(noResult: true);
  }

  Future<void> addToWatchlist(Map<String, dynamic> movieData) async {
    final db = await database; 
    await db.insert('watchlist', {
      'id': movieData['id'],
      'title': movieData['title'],
      'poster_path': movieData['poster_path'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> isMovieInWatchlist(int movieId) async {
    final db = await database; 
    final List<Map<String, dynamic>> maps = await db.query(
      'watchlist',
      where: 'id = ?',
      whereArgs: [movieId],
    );
    return maps.isNotEmpty;
  }

  Future<void> removeFromWatchlist(int movieId) async {
    final db = await database; 
    await db.delete('watchlist', where: 'id = ?', whereArgs: [movieId]);
    print('Film ID $movieId dihapus dari watchlist.');
  }

  Future<List<Map<String, dynamic>>> getWatchlist() async {
    final db =
        await database; 

    final List<Map<String, dynamic>> maps = await db.query('watchlist');

    return maps;
  }
}

final dbHelper = DatabaseHelper();
