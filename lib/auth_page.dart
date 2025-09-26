import 'package:flutter/material.dart';                 // Like importing Android UI libs
import 'package:firebase_auth/firebase_auth.dart';      // Firebase Auth SDK (similar to adding a dependency in Java)

// Stateful screen (like an Android Activity/Fragment with internal state)
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  // Factory for the State object (think: creates the controller for this UI)
  @override
  State<AuthPage> createState() => _AuthPageState();
}

// Enum = fixed set of constants (like Java enum)
enum AuthMode { signIn, signUp, reset }

// This is the "controller" for the widget above; holds fields, lifecycle, and UI building.
// Comparable to an Activity with member fields and lifecycle methods (onCreate/onDestroy).
class _AuthPageState extends State<AuthPage> {
  // Form key = handle to the <Form> widget so we can call validate() like form.validate()
  final _formKey = GlobalKey<FormState>();

  // Text controllers = like Java TextWatcher + model in one; they hold current text values.
  final _fullNameController = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  // Current mode (like a screen state flag): sign in / sign up / reset
  AuthMode _mode = AuthMode.signIn;

  // Spinner flag (like showing/hiding ProgressBar in Android)
  bool _loading = false;

  // For displaying error messages in the UI
  String? _error;

  @override
  void dispose() {
    // Lifecycle: called when this UI is permanently removed.
    // Release resources (like calling close() in Java) to avoid memory leaks.
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  // ---------------- Validators (similar to input validation in Android TextInputLayout) ----------------

  // Returns a String error message or null if OK (same pattern as many Java validators)
  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);  // simple regex check
    if (!ok) return 'Enter a valid email';
    return null; // null => valid
  }

  String? _validatePassword(String? v) {
    if (_mode == AuthMode.reset) return null;               // no password needed for reset
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Min 6 characters';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (_mode != AuthMode.signUp) return null;              // confirm only applies to sign up
    if (v != _password.text) return 'Passwords do not match';
    return null;
  }

  // ---------------- Main action handler (like onClick handler + async Firebase calls) ----------------
  Future<void> _submit() async {
    // Hide soft keyboard (like InputMethodManager.hideSoftInputFromWindow)
    FocusScope.of(context).unfocus();

    // Trigger validators on all fields in the Form; abort if any invalid
    if (!_formKey.currentState!.validate()) return;

    // Set "loading" state and clear previous error; triggers a rebuild (like setState in Android)
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Get FirebaseAuth singleton (like FirebaseAuth.getInstance() in Java)
      final auth = FirebaseAuth.instance;

      if (_mode == AuthMode.signIn) {
        // ---------- SIGN IN flow ----------
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        _snack('Signed in'); // Toast/Snackbar equivalent
        if (mounted) Navigator.of(context).pushReplacementNamed('/home'); // startActivity + finish()

      } else if (_mode == AuthMode.signUp) {
        // ---------- SIGN UP flow ----------
        final cred = await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );

        // After account creation, set the Firebase user's displayName (profile) like:
        // FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
        // user.updateProfile(new UserProfileChangeRequest.Builder().setDisplayName(...).build());
        final fullName = _fullNameController.text.trim();
        await cred.user!.updateDisplayName(fullName);
        await cred.user!.reload(); // refresh cached user info

        _snack('Account created');
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');

      } else {
        // ---------- RESET PASSWORD flow ----------
        await auth.sendPasswordResetEmail(email: _email.text.trim());
        _snack('Password reset email sent');
        // Return to Sign In screen state
        setState(() => _mode = AuthMode.signIn);
      }

    } on FirebaseAuthException catch (e) {
      // Firebase-specific error (e.g., wrong-password, user-not-found)
      setState(() => _error = e.message ?? 'Authentication error');
    } catch (_) {
      // Generic catch-all (like catching Exception in Java)
      setState(() => _error = 'Something went wrong');
    } finally {
      // Always clear loading flag (finally runs even if exception thrown)
      if (mounted) setState(() => _loading = false);
    }
  }

  // Convenience: show a Snackbar (Android Toast-like, but material)
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // Booleans derived from the enum (like if(mode == SIGN_UP) in Java)
    final isSignIn = _mode == AuthMode.signIn;
    final isSignUp = _mode == AuthMode.signUp;
    final isReset  = _mode == AuthMode.reset;

    // Scaffold = top-level screen structure (like an Activity with AppBar + content)
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420), // keep card narrow on large screens
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 3, // drop shadow
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey, // hook validators
                child: Column(
                  mainAxisSize: MainAxisSize.min, // wrap content vertically
                  children: [
                    // ---- Error banner (shows server-side/auth errors) ----
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!, // non-null because guarded by if
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),

                    // ---- Full name field (only for sign-up) ----
                    if (isSignUp) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next, // move focus to next field on "next"
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        autofillHints: const [AutofillHints.name], // OS autofill hint
                        validator: (value) {
                          if (!isSignUp) return null;     // no check in other modes
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Please enter your full name';
                          if (v.length < 2) return 'Name looks too short';
                          return null;
                        },
                      ),
                    ],

                    // ---- Email field ----
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,   // email keyboard
                      autofillHints: const [AutofillHints.email], // OS autofill hint
                      validator: _validateEmail,                  // call our validator
                    ),

                    // ---- Password field (hidden during reset mode) ----
                    if (!isReset) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true, // password dots
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: _validatePassword,
                      ),
                    ],

                    // ---- Confirm password (sign-up only) ----
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

                    // ---- Primary action button: Sign In / Sign Up / Reset ----
                    SizedBox(
                      width: double.infinity, // stretch button to full width
                      child: FilledButton(
                        onPressed: _loading ? null : _submit, // disable while loading
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

                    // ---- Footer links (toggle modes) ----
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Toggle between Sign In and Sign Up
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

                        // Go to Reset Password mode
                        if (!isReset)
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() => _mode = AuthMode.reset),
                            child: const Text('Forgot password?'),
                          ),

                        // From Reset back to Sign In
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
