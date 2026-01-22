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
    String path = join(await getDatabasesPath(), 'movie_app_ultimate.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE watchlist(id INTEGER PRIMARY KEY, title TEXT, poster_path TEXT)');
        await db.execute('CREATE TABLE reviews(id INTEGER PRIMARY KEY AUTOINCREMENT, movie_id INTEGER, user_name TEXT, rating REAL, comment TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)');
      },
    );
  }

  // --- WATCHLIST ---
  Future<void> addToWatchlist(Map<String, dynamic> movie) async {
    final db = await database;
    await db.insert('watchlist', movie, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFromWatchlist(int id) async {
    final db = await database;
    await db.delete('watchlist', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isMovieInWatchlist(int id) async {
    final db = await database;
    final res = await db.query('watchlist', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getWatchlist() async {
    final db = await database;
    return await db.query('watchlist');
  }

  // --- REVIEWS ---
  Future<void> insertReview(Map<String, dynamic> data) async {
    final db = await database;
    Map<String, dynamic> cleanData = Map.from(data);
    cleanData['movie_id'] = int.tryParse(data['movie_id'].toString()) ?? 0;
    // Membolehkan comment kosong
    cleanData['comment'] = (cleanData['comment'] ?? "").toString().trim();
    await db.insert('reviews', cleanData);
  }

  Future<List<Map<String, dynamic>>> getReviewsByMovie(dynamic movieId) async {
    final db = await database;
    final intId = int.tryParse(movieId.toString()) ?? 0;
    return await db.query('reviews', where: 'movie_id = ?', whereArgs: [intId], orderBy: 'timestamp DESC');
  }

  Future<bool> hasUserRated(dynamic movieId, String userName) async {
    final db = await database;
    final intId = int.tryParse(movieId.toString()) ?? 0;
    final result = await db.query('reviews', where: 'movie_id = ? AND user_name = ? AND rating > 0', whereArgs: [intId, userName]);
    return result.isNotEmpty;
  }
}
final dbHelper = DatabaseHelper();