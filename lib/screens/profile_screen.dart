// Profile Screen: editable user profile (name, email, password).
// Styled like login page with gradient background and rounded inputs.

import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';
import '../services/auth_service.dart';
import '../services/local_db_service.dart';
import '../screens/help_screen.dart';
import '../screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppSettingsService settings;
  final VoidCallback? onLoggedOut;

  const ProfileScreen({
    super.key,
    required this.settings,
    this.onLoggedOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  AppUser? _user;
  String? _status;
  bool _busy = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = await _auth.currentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _nameController.text = user?.name ?? '';
      _emailController.text = user?.email ?? '';
    });
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _status = 'Please enter a name.');
      return;
    }
    if (!_isValidEmail(_emailController.text)) {
      setState(() => _status = 'Please enter a valid email.');
      return;
    }

    setState(() { _busy = true; _status = null; });

    final user = _user;
    if (user != null && user.email.isNotEmpty) {
      try {
        await _updateUserRecord(
          user.email,
          _nameController.text.trim(),
          _emailController.text.trim(),
        );
        final pw = _newPasswordController.text.isNotEmpty
            ? _newPasswordController.text
            : null;
        if (pw != null || _emailController.text != user.email) {
          final err = await _auth.login(
            email: _emailController.text,
            password: pw ?? _currentPassword(),
          );
          if (err != null) {
            setState(() {
              _busy = false;
              _status = err;
            });
            return;
          }
        }
        if (!mounted) return;
        setState(() {
          _busy = false;
          _user = AppUser(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
          );
          _status = 'Profile saved.';
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _status = 'Save failed: $e';
        });
      }
    } else {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'No account to update.';
      });
    }
  }

  Future<void> _deletePassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete saved password?'),
        content: const Text(
          'This removes your saved password. You will need to register '
          'again to log in. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final user = _user;
    if (user == null || user.email.isEmpty) return;
    setState(() { _busy = true; _status = null; });
    try {
      await _updateUserPassword(user.email, '');
      await _auth.logout();
      if (!mounted) return;
      widget.onLoggedOut?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Could not delete password: $e';
      });
    }
  }

  String _currentPassword() => '';

  bool _isValidEmail(String email) {
    final e = email.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  Future<void> _updateUserRecord(
      String oldEmail, String newName, String newEmail) async {
    final db = await LocalDbService.instance.database;
    await db.update(
      'users',
      {'name': newName, 'email': newEmail.toLowerCase()},
      where: 'email = ?',
      whereArgs: [oldEmail.toLowerCase()],
    );
  }

  Future<void> _updateUserPassword(String email, String newPassword) async {
    final db = await LocalDbService.instance.database;
    await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1E3A8A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary,
              primary.withValues(alpha: 0.7),
              const Color(0xFF60A5FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.health_and_safety,
                      size: 52,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Welcome heading
                  const Text(
                    "My Profile",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Edit your account details",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Profile form card
                  Card(
                    color: Colors.white,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          // Avatar placeholder
                          const CircleAvatar(
                            radius: 34,
                            backgroundColor: Color(0xFF1E3A8A),
                            child: Icon(Icons.person, size: 34, color: Colors.white),
                          ),
                          const SizedBox(height: 16),

                          // Name field
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              hintStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: primary, width: 2),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Email field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'you@mail.com',
                              hintStyle: const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: primary, width: 2),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Change password
                          const Text(
                            'Change password (optional)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: _obscureNew,
                            decoration: InputDecoration(
                              hintText: 'New password (min 6)',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureNew
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _obscureNew = !_obscureNew),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              hintText: 'Confirm new password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Status message
                          if (_status != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (_status!.startsWith('Save') ||
                                        _status!.startsWith('Password'))
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _status!,
                                style: const TextStyle(
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          if (_status != null) const SizedBox(height: 16),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _saveProfile,
                              icon: _busy
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _busy ? 'Saving...' : 'Save Profile',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Delete password button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _deletePassword,
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              label: const Text(
                                'Delete saved password',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Settings shortcut
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SettingsScreen(settings: widget.settings),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('Settings'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Help shortcut
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HelpScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.help_outline),
                              label: const Text('Help — how to use the app'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Logout
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : () async {
                                await _auth.logout();
                                if (!mounted) return;
                                widget.onLoggedOut?.call();
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text('Log Out'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
