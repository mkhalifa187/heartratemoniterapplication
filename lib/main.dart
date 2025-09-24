import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';   // <-- must be here
import 'auth_page.dart';
import 'home_page.dart';





// ===== SINGLE main() =====

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // <-- uses generated file
  );
  runApp(const MyApp());
}



// ===== APP ROOT =====
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Monitor Auth',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AuthPage(), // start on the auth screen
      routes: {
        '/home': (_) => const HomePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
