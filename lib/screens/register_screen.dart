// Register Screen: name + email + password for new users.

import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  // Called after successful registration (auto login).
  final VoidCallback onRegistered;

  const RegisterScreen({super.key, required this.onRegistered});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Auth logic lives in this service.
  final AuthService _auth = AuthService();

  // Controllers for the three input boxes.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Error text shown under the button.
  String? _error;

  // Spinner while waiting for storage.
  bool _busy = false;

  @override
  void dispose() {
    // Free controllers when screen closes.
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Try to create the account with typed details.
  Future<void> _doRegister() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    // Ask the auth module to store the new user.
    final err = await _auth.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _busy = false);

    // Show error, or go back + notify app on success.
    if (err != null) {
      setState(() => _error = err);
    } else {
      if (mounted) Navigator.pop(context);
      widget.onRegistered();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar with back button.
      appBar: AppBar(title: const Text('Register'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                'Create your profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Name input box.
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

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

              // Password input box.
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (min 4 chars)',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _doRegister(),
              ),
              const SizedBox(height: 12),

              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_error != null) const SizedBox(height: 8),

              // Register button.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _doRegister,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
