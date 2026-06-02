import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/firebase_service.dart';
import '../data/hive_service.dart';
import 'signup_page.dart';
import 'setup_profile_screen.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _emailError = '';
  String _passwordError = '';
  String _generalError = '';

  bool _passwordVisible = false;
  bool _isLoading = false;
  bool _isRestoring = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _emailError = '';
      _passwordError = '';
      _generalError = '';
    });

    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = 'Email is required');
      valid = false;
    } else if (!RegExp(
      r'^[\w.-]+@[\w.-]+\.\w+$',
    ).hasMatch(_emailController.text.trim())) {
      setState(() => _emailError = 'Enter a valid email');
      valid = false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      valid = false;
    } else if (_passwordController.text.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      valid = false;
    }

    return valid;
  }

  Future<void> _login() async {
    if (!_validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);

    // 1. Firebase sign in
    final error = await FirebaseService.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
        _generalError = error;
      });
      return;
    }

    // 2. Email verification check
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await FirebaseService.signOut();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _generalError =
            'Email not verified. Please check your inbox and verify before signing in.';
      });
      return;
    }

    // 3. Restore Hive from Firestore if local cache is missing (fresh install / reinstall)
    //    This must happen before we decide where to navigate.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final loginEmail = _emailController.text.trim();

    // 4. First sync the login email to Firestore, Then restore Hive
    //    so Hive always gets the updated email.
    if (uid != null) {
      await FirebaseService.syncEmail(uid, loginEmail);
    }

    if (HiveService.isHiveEmpty()) {
      setState(() => _isRestoring = true);
      if (uid != null) {
        try {
          final data = await FirebaseService.fetchUserProfile(uid);
          if (data != null) await HiveService.restoreFromMap(data);
        } catch (e) {
          debugPrint('[LoginPage] restore error: $e');
        }
      }
    } else {
      // Hive already has data — just update the email field locally too
      await HiveService.saveProfile(
        name: HiveService.name,
        email: loginEmail,
        avatarPath: HiveService.avatarPath,
      );
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isRestoring = false;
    });

    // 5. Navigate based on restored (or existing) Hive state.
    //    isProfileSetup is now accurate — read it after the restore above.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HiveService.isProfileSetup
            ? const HomePage()
            : const SetupProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE50914), Color(0xFFB20710)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE50914).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.movie_filter_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Center(
                child: Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Sign in to CineVault',
                  style: TextStyle(fontSize: 15, color: Color(0xFF6B6B80)),
                ),
              ),

              const SizedBox(height: 40),

              // Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF141420),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Email'),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _emailController,
                      hint: 'you@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      error: _emailError,
                    ),

                    const SizedBox(height: 20),
                    _label('Password'),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _passwordController,
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      error: _passwordError,
                    ),

                    if (_generalError.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _errorBox(_generalError),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE50914),
                          disabledBackgroundColor: const Color(
                            0xFFE50914,
                          ).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  if (_isRestoring) ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Restoring your data...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: const TextStyle(
                      color: Color(0xFF6B6B80),
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: const TextStyle(
                          color: Color(0xFFE50914),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpPage(),
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  //  Helpers
  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: Color(0xFFB0B0C0),
    ),
  );

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade900.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.shade800),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.error_outline,
            color: Colors.red.shade400,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: TextStyle(color: Colors.red.shade300, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String error = '',
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error.isNotEmpty
                  ? Colors.red.shade700
                  : const Color(0xFF2A2A3A),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !_passwordVisible,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF4A4A5A)),
              prefixIcon: Icon(icon, color: const Color(0xFF6B6B80), size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF6B6B80),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
