import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_page.dart'; // make sure this import is correct

/// Simple landing page shown after a successful sign-in.
/// Replace this with your real app (tabs, forms, ML, etc.).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // --- Method to sign out and go back to AuthPage ---
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Clear navigation stack and go back to AuthPage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Grab display name from Firebase user
    final name = FirebaseAuth.instance.currentUser?.displayName ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $name 👋'),
        actions: [
          // --- Pretty pill-style Sign out button ---
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: const Text('Sign out'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, // text/icon color
                backgroundColor: Colors.redAccent, // pill background
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // pill shape
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, $name 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Signed in! 🎉\nBuild your app here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
