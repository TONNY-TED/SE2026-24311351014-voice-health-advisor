// Authentication Module: register, login, save user profile locally.
// Uses shared_preferences so the session survives app restarts.
// NOTE (for report): passwords are plain text here — demo only, not production.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
  // Key prefix for each registered user: users_<email>.
  static const String _userPrefix = 'users_';

  // Key holding the logged-in email (null = logged out).
  static const String _currentUserKey = 'current_user_email';

  // Register a new user. Returns null on success, error message on failure.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Basic validation so empty / bad input never gets stored.
    if (name.trim().isEmpty) return 'Please enter your name.';
    if (!_isValidEmail(email)) return 'Please enter a valid email.';
    if (password.length < 4) return 'Password must be at least 4 characters.';

    final prefs = await SharedPreferences.getInstance();
    final key = _userPrefix + email.trim().toLowerCase();

    // Block duplicate accounts for the same email.
    if (prefs.containsKey(key)) {
      return 'This email is already registered. Please log in.';
    }

    // Save user record including password (demo only).
    final record = jsonEncode({
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    await prefs.setString(key, record);

    // Auto log in right after registration.
    await prefs.setString(_currentUserKey, email.trim().toLowerCase());
    return null;
  }

  // Log in with email + password. Returns null on success, error on failure.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    if (!_isValidEmail(email)) return 'Please enter a valid email.';
    if (password.isEmpty) return 'Please enter your password.';

    final prefs = await SharedPreferences.getInstance();
    final key = _userPrefix + email.trim().toLowerCase();
    final raw = prefs.getString(key);

    // No account found for this email.
    if (raw == null) return 'No account found. Please register first.';

    final data = jsonDecode(raw) as Map<String, dynamic>;

    // Wrong password check.
    if (data['password'] != password) {
      return 'Wrong password. Try again.';
    }

    // Save login session.
    await prefs.setString(_currentUserKey, email.trim().toLowerCase());
    return null;
  }

  // Log out: clear only the session, keep registered accounts.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Get the currently logged-in user profile, or null if logged out.
  Future<AppUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_currentUserKey);
    if (email == null) return null;

    final raw = prefs.getString(_userPrefix + email);
    if (raw == null) return null;

    final data = jsonDecode(raw) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  // Very small email check: must contain @ and a dot.
  bool _isValidEmail(String email) {
    final e = email.trim();
    return e.contains('@') && e.contains('.');
  }
}
