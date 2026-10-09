// Register Screen: polished card UI + validation for name/email/password.

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

  // Form key validates all fields together before register.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for the three input boxes.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Server-side error (e.g. duplicate email).
  String? _error;

  // Spinner while waiting for storage.
  bool _busy = false;

  // Show/hide password toggle.
  bool _obscure = true;

  @override
  void dispose() {
    // Free controllers when screen closes.
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Try to create the account: validate form first, then store user.
  Future<void> _doRegister() async {
    // Stop if any field format is invalid.
    if (!_formKey.currentState!.validate()) return;

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

    if (!mounted) return;
    setState(() => _busy = false);

    // Show error, or go back + notify app on success.
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.pop(context);
      widget.onRegistered();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(title: const Text('Create account'), centerTitle: true),
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_alt,
                        size: 56, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your profile',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Saved on this device',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),

                    // Name box: min 2 chars.
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        hintText: 'e.g. Ama Mensah',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: AuthService.validateName,
                    ),
                    const SizedBox(height: 12),

                    // Email box: must match name@domain.tld.
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@mail.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: AuthService.validateEmail,
                    ),
                    const SizedBox(height: 12),

                    // Password box: min 6 chars + show/hide.
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Min 6 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: AuthService.validatePassword,
                      onFieldSubmitted: (_) => _doRegister(),
                    ),
                    const SizedBox(height: 12),

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

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _doRegister,
                        icon: _busy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check),
                        label:
                            Text(_busy ? 'Creating...' : 'Register'),
                      ),
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
