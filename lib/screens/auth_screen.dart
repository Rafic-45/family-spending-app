import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// Name + password sign in / sign up. No email, no verification.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final name = _nameController.text;
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        await _auth.signUp(name: name, password: password);
      } else {
        await _auth.signIn(name: name, password: password);
      }
      // AuthGate reacts to the auth state change and swaps the screen.
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(_friendlyMessage(e.message));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Something went wrong. Please try again.');
    }
  }

  String _friendlyMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'That name is already taken. Try signing in instead.';
    }
    if (lower.contains('invalid login') || lower.contains('invalid credentials')) {
      return 'Wrong name or password.';
    }
    if (lower.contains('password')) {
      return 'Password must be at least 6 characters.';
    }
    return raw;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('💸', style: theme.textTheme.displaySmall),
                    const SizedBox(height: 8),
                    Text('Family Spend',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _isSignUp
                          ? 'Create an account for yourself'
                          : 'Welcome back',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Your name',
                        hintText: 'e.g. Rafic',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'At least 6 characters'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isSignUp ? 'Create account' : 'Sign in'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(_isSignUp
                          ? 'I already have an account'
                          : "I'm new — create an account"),
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
