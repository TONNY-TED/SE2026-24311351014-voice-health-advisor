// SQLite on-device database (Step: local storage).
// Tables: users (profile + password) and history (queries per logged-in user).
// Web (Chrome) can't use sqflite, so AuthService falls back to prefs there.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LocalDbService {
  // Single shared instance (one open database).
  static final LocalDbService instance = LocalDbService._();
  LocalDbService._();

  // Cached open database.
  Database? _db;

  // Open (or create) the app database with both tables.
  Future<Database> get database async {
    // Return existing connection if already open.
    if (_db != null) return _db!;

    // Database file lives in the app documents directory.
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'healthcare_assistant.db');

    // Open + create tables on first run (version 1).
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Users table: one row per registered email.
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          )
        ''');

        // History table: every advice query while logged in.
        await db.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            query TEXT NOT NULL,
            topic TEXT NOT NULL,
            intent TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  // Insert a new user. Returns false when email already exists.
  Future<bool> insertUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await database;
    try {
      await db.insert('users', {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      return true;
    } catch (_) {
      // UNIQUE constraint fails on duplicate email.
      return false;
    }
  }

  // Look up one user by email (null when not registered).
  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  // Save one history row for the logged-in user.
  Future<void> addHistory({
    required String email,
    required String query,
    required String topic,
    required String intent,
  }) async {
    final db = await database;
    await db.insert('history', {
      'email': email.trim().toLowerCase(),
      'query': query,
      'topic': topic,
      'intent': intent,
      // ISO timestamp, newest-first ordering.
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Recent queries for one user (for Week 5 History UI).
  Future<List<Map<String, dynamic>>> recentHistory(
    String email, {
    int limit = 20,
  }) async {
    final db = await database;
    return db.query(
      'history',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      orderBy: 'id DESC',
      limit: limit,
    );
  }

  // Clear all history rows for one user (history screen button).
  Future<void> clearHistory(String email) async {
    final db = await database;
    await db.delete(
      'history',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }
}
