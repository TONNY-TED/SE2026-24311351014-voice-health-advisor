// Login Screen: polished card UI + form validation for credentials.

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

  // Form key validates all fields together before login.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for the two input boxes.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Server-side error (e.g. wrong password) shown under the button.
  String? _error;

  // Spinner while waiting for storage.
  bool _busy = false;

  // Show/hide password toggle.
  bool _obscure = true;

  @override
  void dispose() {
    // Free controllers when screen closes.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Try to log in: first validate form, then check stored credentials.
  Future<void> _doLogin() async {
    // Stop if email/password format is invalid (shows inline errors).
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    // Ask the auth module to validate credentials.
    final err = await _auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
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
      // Soft background so the white card stands out.
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(title: const Text('Healthcare Assistant'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              // Form enables validate() on all TextFormFields at once.
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.health_and_safety,
                        size: 56, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text(
                      'Welcome back',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Log in to continue',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),

                    // Email box with format validation.
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@mail.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      // Reuse shared email rule from AuthService.
                      validator: AuthService.validateEmail,
                    ),
                    const SizedBox(height: 12),

                    // Password box with length validation + show/hide toggle.
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        // Eye icon toggles hidden text.
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: AuthService.validatePassword,
                      onFieldSubmitted: (_) => _doLogin(),
                    ),
                    const SizedBox(height: 12),

                    // Auth failure message (wrong password / no account).
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    if (_error != null) const SizedBox(height: 8),

                    // Full-width login button.
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _doLogin,
                        icon: _busy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.login),
                        label: Text(_busy ? 'Please wait...' : 'Log In'),
                      ),
                    ),

                    // Link to registration for new users.
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(
                                onRegistered: widget.onLoggedIn),
                          ),
                        );
                      },
                      child: const Text("No account? Register here"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
