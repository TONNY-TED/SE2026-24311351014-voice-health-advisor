// Authentication Module: register, login, save user profile locally.
// Storage: SQLite users table on phone/desktop, SharedPreferences fallback on web.
// Session (logged-in email) stays in SharedPreferences on all platforms.
// NOTE (for report): passwords are plain text here — demo only, not production.

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'local_db_service.dart';

// Simple user profile model.
class AppUser {
  // Display name entered at registration.
  final String name;

  // Email acts as the unique login ID.
  final String email;

  const AppUser({required this.name, required this.email});

  // Convert to JSON for storage.
  Map<String, dynamic> toJson() => {'name': name, 'email': email};

  // Rebuild from stored JSON.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class AuthService {
  // Web fallback keys (SQLite unavailable on Chrome).
  static const String _userPrefix = 'users_';

  // Key holding the logged-in email (null = logged out).
  static const String _currentUserKey = 'current_user_email';

  // SQLite database for on-device user rows.
  final LocalDbService _db = LocalDbService.instance;

  // Register a new user. Returns null on success, error message on failure.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Basic validation so empty / bad input never gets stored.
    if (name.trim().isEmpty) return 'Please enter your name.';
    if (name.trim().length < 2) return 'Name must be at least 2 characters.';
    if (!_isValidEmail(email)) {
      return 'Please enter a valid email e.g. you@mail.com.';
    }
    if (password.length < 6) return 'Password must be at least 6 characters.';

    final cleanEmail = email.trim().toLowerCase();
    bool inserted;

    // Phone/desktop: SQLite users table.
    if (!kIsWeb) {
      try {
        inserted = await _db.insertUser(
          name: name.trim(),
          email: cleanEmail,
          password: password,
        );
      } catch (_) {
        // DB unavailable (e.g. first-run lock): fall back to prefs.
        inserted = await _prefsInsertUser(name.trim(), cleanEmail, password);
      }
    } else {
      // Chrome web: SharedPreferences mirror of the same record.
      inserted = await _prefsInsertUser(name.trim(), cleanEmail, password);
    }

    // Block duplicate accounts for the same email.
    if (!inserted) {
      return 'This email is already registered. Please log in.';
    }

    // Auto log in right after registration.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, cleanEmail);
    return null;
  }

  // Log in with email + password. Returns null on success, error on failure.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    if (!_isValidEmail(email)) return 'Please enter a valid email.';
    if (password.isEmpty) return 'Please enter your password.';

    final cleanEmail = email.trim().toLowerCase();
    Map<String, dynamic>? record;

    // Phone/desktop: read from SQLite, fallback to prefs on failure.
    if (!kIsWeb) {
      try {
        record = await _db.getUser(cleanEmail);
      } catch (_) {
        record = await _prefsGetUser(cleanEmail);
      }
      // No SQLite row yet (e.g. account made on web): check prefs mirror.
      record ??= await _prefsGetUser(cleanEmail);
    } else {
      record = await _prefsGetUser(cleanEmail);
    }

    // No account found for this email.
    if (record == null) return 'No account found. Please register first.';

    // Wrong password check.
    if (record['password'] != password) {
      return 'Wrong password. Try again.';
    }

    // Save login session.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, cleanEmail);
    return null;
  }

  // Log out: clear only the session, keep stored accounts + history.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Get the currently logged-in user profile, or null if logged out.
  Future<AppUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_currentUserKey);
    if (email == null) return null;

    // Prefer SQLite row, fall back to prefs mirror.
    if (!kIsWeb) {
      try {
        final row = await _db.getUser(email);
        if (row != null) {
          return AppUser(
            name: row['name']?.toString() ?? '',
            email: row['email']?.toString() ?? email,
          );
        }
      } catch (_) {
        // Fall through to prefs mirror.
      }
    }
    final raw = prefs.getString(_userPrefix + email);
    if (raw == null) return AppUser(name: '', email: email);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  // ---- Web / fallback mirror in SharedPreferences ----

  // Insert prefs mirror record. False when email already exists.
  Future<bool> _prefsInsertUser(String name, String email, String pw) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userPrefix + email;
    if (prefs.containsKey(key)) return false;
    await prefs.setString(
      key,
      jsonEncode({'name': name, 'email': email, 'password': pw}),
    );
    return true;
  }

  // Read prefs mirror record (null when missing).
  Future<Map<String, dynamic>?> _prefsGetUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userPrefix + email);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // Email format check: name@domain.tld (trims spaces, lowercases).
  bool _isValidEmail(String email) {
    final e = email.trim();
    // Simple but solid pattern: something@something.something
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return pattern.hasMatch(e);
  }

  // Public validators reused by login/register forms (return error or null).
  // Name must be at least 2 letters.
  static String? validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your name.';
    if (v.trim().length < 2) return 'Name must be at least 2 characters.';
    return null;
  }

  // Email must match name@domain.tld pattern.
  static String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your email.';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(v.trim())) {
      return 'Enter a valid email e.g. you@mail.com.';
    }
    return null;
  }

  // Password: min 6 chars so short/guessable passwords are rejected.
  static String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your password.';
    if (v.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }
}
