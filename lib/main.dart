import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'data/firebase_service.dart';
import 'data/hive_service.dart';
import 'ui/login_page.dart';
import 'ui/home.dart';
import 'ui/setup_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Hive (local cache)
  await HiveService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CineVault',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        primaryColor: const Color(0xFFE50914),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE50914),
          secondary: Color(0xFFFFB800),
          surface: Color(0xFF141420),
        ),
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0A0A0F),
          selectedItemColor: Color(0xFFE50914),
          unselectedItemColor: Color(0xFF6B6B80),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

/*
Decides which screen to show on app launch.
Flow:
  Not logged in               -> LoginPage
  Logged in + Hive has data   -> HomePage  (fast path, no network)
  Logged in + Hive is empty   -> fetch Firestore, then:
     profile exists           -> restore Hive  -> HomePage
     no profile in Firestore  -> SetupProfileScreen
*/
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  // null = still resolving, true = ready to show home, false = needs setup
  bool? _profileReady;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Still waiting for Firebase auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _splash();
        }

        final user = snapshot.data;

        // 2. Not logged in
        if (user == null) {
          _profileReady = null; // reset for next login
          return const LoginPage();
        }

        // 3. Logged in

        // Fast path: Hive already has data (normal app restart)
        if (!HiveService.isHiveEmpty()) {
          return HiveService.isProfileSetup
              ? const HomePage()
              : const SetupProfileScreen();
        }

        // Hive is empty (reinstall / data cleared).
        // We need to fetch from Firestore before deciding.
        if (_profileReady == null) {
          // Kick off the async restore once, then rebuild.
          _restoreAndDecide(user.uid);
          return _splash(); // show spinner while fetching
        }

        // Restore finished — navigate.
        return _profileReady! ? const HomePage() : const SetupProfileScreen();
      },
    );
  }

  Future<void> _restoreAndDecide(String uid) async {
    try {
      final data = await FirebaseService.fetchUserProfile(uid);
      if (data != null) {
        await HiveService.restoreFromMap(data);
        if (mounted) setState(() => _profileReady = true);
      } else {
        // No Firestore record -> brand-new user who lost local data
        if (mounted) setState(() => _profileReady = false);
      }
    } catch (e) {
      debugPrint('[AuthGate] restore error: $e');
      // On network failure, fall through to SetupProfileScreen so the
      // user is never stuck. They can always log out and retry.
      if (mounted) setState(() => _profileReady = false);
    }
  }

  Widget _splash() => const Scaffold(
    backgroundColor: Color(0xFF0A0A0F),
    body: Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
  );
}
