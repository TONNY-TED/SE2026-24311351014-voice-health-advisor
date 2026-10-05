// Login Screen: email + password entry for existing users.

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  // Called after a successful login so the app can reload the session.
  final VoidCallback onLoggedIn;

  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Auth logic lives in this service.
  final AuthService _auth = AuthService();

  // Controllers for the two input boxes.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Error text shown under the button (null = no error).
  String? _error;

  // Spinner while waiting for storage.
  bool _busy = false;

  @override
  void dispose() {
    // Free controllers when screen closes.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Try to log in with the typed email + password.
  Future<void> _doLogin() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    // Ask the auth module to validate credentials.
    final err = await _auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _busy = false);

    // Show error or notify the app that login succeeded.
    if (err != null) {
      setState(() => _error = err);
    } else {
      widget.onLoggedIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar for the auth section.
      appBar: AppBar(title: const Text('Log In'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.health_and_safety, size: 64, color: Colors.blue),
              const SizedBox(height: 10),
              const Text(
                'Welcome back',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Email input box.
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Password input box (hidden text).
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _doLogin(),
              ),
              const SizedBox(height: 12),

              // Error message area.
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_error != null) const SizedBox(height: 8),

              // Login button with spinner while busy.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _doLogin,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Log In'),
                ),
              ),
              const SizedBox(height: 8),

              // Link to registration for new users.
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RegisterScreen(onRegistered: widget.onLoggedIn),
                    ),
                  );
                },
                child: const Text("No account? Register here"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
