import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A single screen that can switch between 3 modes:
/// - Sign In
/// - Sign Up
/// - Password Reset
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

/// Modes for the UI state machine
enum AuthMode { signIn, signUp, reset }

class _AuthPageState extends State<AuthPage> {
  // Form key lets us validate and save the form as a whole
  final _formKey = GlobalKey<FormState>();

  // Controllers read/write text field values
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  // Current mode of the screen
  AuthMode _mode = AuthMode.signIn;

  // UI flags for progress & error
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    // Always dispose controllers to avoid memory leaks
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // --- Validators ---

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
    if (!ok) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    // No password needed in reset mode
    if (_mode == AuthMode.reset) return null;
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Min 6 characters';
    return null;
  }

  String? _validateConfirm(String? v) {
    // Only validate confirm field in sign up mode
    if (_mode != AuthMode.signUp) return null;
    if (v != _password.text) return 'Passwords do not match';
    return null;
  }

  // --- Actions ---

  // Handles Sign In / Sign Up / Reset based on current _mode
  Future<void> _submit() async {
    FocusScope.of(context).unfocus(); // dismiss keyboard

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = FirebaseAuth.instance;

      if (_mode == AuthMode.signIn) {
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        _snack('Signed in');
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else if (_mode == AuthMode.signUp) {
        await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        _snack('Account created');
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else {
        await auth.sendPasswordResetEmail(email: _email.text.trim());
        _snack('Password reset email sent');
        setState(() => _mode = AuthMode.signIn);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Authentication error');
    } catch (_) {
      setState(() => _error = 'Something went wrong');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _mode == AuthMode.signIn;
    final isSignUp = _mode == AuthMode.signUp;
    final isReset = _mode == AuthMode.reset;

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // --- Email ---
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: _validateEmail,
                    ),

                    // --- Password (hidden in reset mode) ---
                    if (!isReset) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: _validatePassword,
                      ),
                    ],

                    // --- Confirm password (only in sign up mode) ---
                    if (isSignUp) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirm,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: _validateConfirm,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Primary button changes text/action by mode
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(
                          isReset
                              ? 'Send Reset Email'
                              : isSignIn
                              ? 'Sign In'
                              : 'Sign Up',
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Secondary actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isReset)
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() => _mode =
                            isSignIn ? AuthMode.signUp : AuthMode.signIn),
                            child: Text(
                              isSignIn
                                  ? 'Create an account'
                                  : 'Have an account? Sign in',
                            ),
                          ),
                        if (!isReset) const SizedBox(width: 8),
                        if (!isReset)
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() => _mode = AuthMode.reset),
                            child: const Text('Forgot password?'),
                          ),
                        if (isReset)
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() => _mode = AuthMode.signIn),
                            child: const Text('Back to sign in'),
                          ),
                      ],
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
