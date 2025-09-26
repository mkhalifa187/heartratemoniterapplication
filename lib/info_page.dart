// info_page.dart
import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {                 // NEW
  const InfoPage({super.key});                           // NEW

  @override
  Widget build(BuildContext context) {                   // NEW
    return Scaffold(                                     // NEW
      appBar: AppBar(title: const Text('Information')),  // NEW
      body: const Center(                                // NEW
        child: Padding(                                  // NEW
          padding: EdgeInsets.all(16),                   // NEW
          child: Text(                                   // NEW
            'App information goes here.\n\n'             // NEW
                '• Version: 1.0.0\n'
                '• Author: You\n'
                '• Notes: Replace with real content.',       // NEW
            textAlign: TextAlign.center,                 // NEW
            style: TextStyle(fontSize: 18),              // NEW
          ),                                             // NEW
        ),                                               // NEW
      ),                                                 // NEW
    );                                                   // NEW
  }                                                      // NEW
}                                                        // NEW
