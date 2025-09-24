import 'package:flutter/material.dart';

/// Simple landing page shown after a successful sign-in.
/// Replace this with your real app (tabs, forms, ML, etc.).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(
        child: Text(
          'Signed in! 🎉\nBuild your app here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
