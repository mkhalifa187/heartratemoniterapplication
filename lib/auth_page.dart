import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// This screen allows users to:
// - Sign In
// - Sign Up
// - Reset their password
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

// The different modes the screen can show
enum AuthMode { signIn, signUp, reset }

class _AuthPageState extends State<AuthPage> {
  // A key used to check if the form is valid
  final _formKey = GlobalKey<FormState>();

  // Text controllers store what the user types
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  // The current mode (default is Sign In)
  AuthMode _mode = AuthMode.signIn;

  // Whether the app is waiting for Firebase (spinner)
  bool _loading = false;

  // Store error messages here (shown above the form)
  String? _error;

  @override
  void dispose() {
    // Always clean up controllers when done
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // --- Validators (check inputs) ---

  // Check if email looks correct
  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
    if (!ok) return 'Enter a valid email';
    return null;
  }

  // Check password rules
  String? _validatePassword(String? v) {
    if (_mode == AuthMode.reset) return null; // not needed for reset
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Min 6 characters';
    return null;
  }

  // Confirm password must match when signing up
  String? _validateConfirm(String? v) {
    if (_mode != AuthMode.signUp) return null;
    if (v != _password.text) return 'Passwords do not match';
    return null;
  }

  // --- Main action button (Sign In / Sign Up / Reset) ---
  Future<void> _submit() async {
    // Hide the keyboard
    FocusScope.of(context).unfocus();

    // Stop if inputs are invalid
    if (!_formKey.currentState!.validate()) return;

    // Show spinner and reset error
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Firebase authentication instance
      final auth = FirebaseAuth.instance;

      if (_mode == AuthMode.signIn) {
        // Try signing in
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        _snack('Signed in');
        // Go to home page if successful
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else if (_mode == AuthMode.signUp) {
        // Try creating a new account
        await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        _snack('Account created');
        // Go to home page if successful
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Send a password reset email
        await auth.sendPasswordResetEmail(email: _email.text.trim());
        _snack('Password reset email sent');
        // Switch back to sign in screen
        setState(() => _mode = AuthMode.signIn);
      }
    } on FirebaseAuthException catch (e) {
      // Show Firebase error
      setState(() => _error = e.message ?? 'Authentication error');
    } catch (_) {
      // Show generic error
      setState(() => _error = 'Something went wrong');
    } finally {
      // Stop spinner
      if (mounted) setState(() => _loading = false);
    }
  }

  // Show a small popup message at the bottom
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // Flags for which mode we are in
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
                    // Show error message if present
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // Email field
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

                    // Password field (hidden in reset mode)
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

                    // Confirm password (only in sign up mode)
                    if (isSignUp) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirm,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Re-enter Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: _validateConfirm,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Main button: Sign In / Sign Up / Reset
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

                    // Links to switch between Sign In / Sign Up / Reset
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
