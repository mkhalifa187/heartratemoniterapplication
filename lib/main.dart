import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'info_page.dart';
import 'firebase_options.dart';
import 'auth_page.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// 🔆 A single place to hold the current ThemeMode
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env before Firebase init
  await dotenv.load(fileName: ".env");

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Monitor Auth',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
        // ✅ Apply Gideon Roman across the app
        textTheme: GoogleFonts.gideonRomanTextTheme(
          Theme.of(context).textTheme.apply(
            fontSizeFactor: 1.2, // 👈 makes all text 20% bigger
          ),

        ),
      ),



      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
        // ✅ Apply Gideon Roman for dark mode too
        textTheme: GoogleFonts.gideonRomanTextTheme(

          Theme.of(context).textTheme.apply(
            fontSizeFactor: 1.2, // 👈 same for dark mode
          ),

        ),
      ),
      themeMode: ThemeMode.light, // or ThemeMode.system / use your ValueNotifier later
      home: const AuthPage(),
      routes: {
        '/home': (_) => const HomePage(),
        '/info': (_) => const InfoPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
