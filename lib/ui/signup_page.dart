import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/firebase_service.dart';
import 'login_page.dart';
import 'setup_profile_screen.dart';

// Three distinct UI states for the sign-up screen.
enum _SignUpState { form, waitingVerification, verified }

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // Error strings
  String _emailError = '';
  String _passwordError = '';
  String _confirmError = '';
  String _generalError = '';

  //  Visibility toggles
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  //  Password strength
  int _passwordStrength = 0;
  String _strengthLabel = '';

  //  Screen state
  _SignUpState _state = _SignUpState.form;
  bool _signing = false; // spinner while creating account

  //  Email verification polling
  Timer? _verifyTimer;

  @override
  void dispose() {
    _verifyTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  //  Password strength helpers
  int _calcStrength(String p) {
    int s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) s++;
    return s;
  }

  void _onPasswordChanged(String value) {
    final s = value.isEmpty ? 0 : _calcStrength(value);
    String label = '';
    if (value.isNotEmpty) {
      if (s <= 1)
        label = 'Weak — add uppercase, numbers & symbols';
      else if (s == 2)
        label = 'Fair — getting better!';
      else if (s == 3)
        label = 'Good — almost there!';
      else
        label = 'Strong password!';
    }
    setState(() {
      _passwordStrength = s;
      _strengthLabel = label;
    });
  }

  Color _barColor(int i) {
    if (_passwordStrength == 0) return const Color(0xFF2A2A3A);
    if (_passwordStrength <= 1)
      return i == 0 ? const Color(0xFFEF4444) : const Color(0xFF2A2A3A);
    if (_passwordStrength == 2)
      return i <= 1 ? const Color(0xFFF59E0B) : const Color(0xFF2A2A3A);
    if (_passwordStrength == 3)
      return i <= 2 ? const Color(0xFF10B981) : const Color(0xFF2A2A3A);
    return const Color(0xFF10B981);
  }

  //  Validation
  bool _validate() {
    bool valid = true;
    setState(() {
      _emailError = '';
      _passwordError = '';
      _confirmError = '';
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
      setState(() => _passwordError = 'Minimum 6 characters');
      valid = false;
    }

    if (_confirmController.text != _passwordController.text) {
      setState(() => _confirmError = 'Passwords do not match');
      valid = false;
    }

    return valid;
  }

  //  Sign Up flow
  Future<void> _signUp() async {
    if (!_validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _signing = true;
      _generalError = '';
    });

    // 1. Create Firebase account
    final error = await FirebaseService.signUp(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _signing = false;
        _generalError = error;
      });
      return;
    }

    // 2. Send verification email
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
    } catch (_) {
      // Non-fatal — user can request resend
    }

    if (!mounted) return;
    setState(() {
      _signing = false;
      _state = _SignUpState.waitingVerification;
    });

    // 3. Start polling every 3 seconds
    _startVerificationPolling();
  }

  void _startVerificationPolling() {
    _verifyTimer?.cancel();
    _verifyTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        await FirebaseAuth.instance.currentUser?.reload();
        final verified =
            FirebaseAuth.instance.currentUser?.emailVerified ?? false;
        if (verified && mounted) {
          _verifyTimer?.cancel();
          setState(() => _state = _SignUpState.verified);
          // Navigate after a short celebration delay
          await Future.delayed(const Duration(milliseconds: 1600));
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SetupProfileScreen()),
          );
        }
      } catch (_) {
        // Ignore transient errors, keep polling
      }
    });
  }

  /// Resend verification email on user request
  Future<void> _resendEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification email resent!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not resend. Try again shortly.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  //  Build
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
              // App icon (always shown)
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

              //  Switch UI based on state
              if (_state == _SignUpState.form) ...[
                const Center(
                  child: Text(
                    'Join CineVault',
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
                    'Create your account to get started',
                    style: TextStyle(fontSize: 15, color: Color(0xFF6B6B80)),
                  ),
                ),
                const SizedBox(height: 36),
                _buildForm(),
                const SizedBox(height: 28),
                _buildSignInLink(),
              ] else if (_state == _SignUpState.waitingVerification) ...[
                const Center(
                  child: Text(
                    'Verify your email',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _emailController.text.trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFE50914),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                _buildWaitingCard(),
              ] else ...[
                const Center(
                  child: Text(
                    'You\'re all set!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                _buildSuccessCard(),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  //  Form card
  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
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
          _buildPasswordField(
            controller: _passwordController,
            hint: '••••••••',
            visible: _passwordVisible,
            onToggle: () =>
                setState(() => _passwordVisible = !_passwordVisible),
            onChange: _onPasswordChanged,
            error: _passwordError,
          ),

          // Strength bar
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: _barColor(i),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _strengthLabel,
              style: TextStyle(
                fontSize: 11,
                color: _passwordStrength <= 1
                    ? Colors.red
                    : _passwordStrength <= 2
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
          ],

          const SizedBox(height: 20),
          _label('Confirm Password'),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _confirmController,
            hint: '••••••••',
            visible: _confirmVisible,
            onToggle: () => setState(() => _confirmVisible = !_confirmVisible),
            error: _confirmError,
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
              onPressed: _signing ? null : _signUp,
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
              child: _signing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Create Account',
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
    );
  }

  //  Waiting-for-verification card
  Widget _buildWaitingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // Animated spinner inside a glowing circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE50914).withValues(alpha: 0.08),
              border: Border.all(
                color: const Color(0xFFE50914).withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                color: Color(0xFFE50914),
                strokeWidth: 3,
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Waiting for verification',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Check your email and click the verification link we sent you. '
            'This screen will update automatically once verified.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          // Resend button
          GestureDetector(
            onTap: _resendEmail,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A3A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF6B6B80),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Resend email',
                    style: TextStyle(
                      color: Color(0xFF6B6B80),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  Success card ─
  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF141420),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Green check circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF10B981),
              size: 40,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Successfully signed up!',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Email verified. Setting up your profile…',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Color(0xFF10B981),
              strokeWidth: 2.5,
            ),
          ),
        ],
      ),
    );
  }

  //  Sign-in link ─
  Widget _buildSignInLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'Already have an account? ',
          style: const TextStyle(color: Color(0xFF6B6B80), fontSize: 14),
          children: [
            TextSpan(
              text: 'Sign In',
              style: const TextStyle(
                color: Color(0xFFE50914),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
            ),
          ],
        ),
      ),
    );
  }

  //  Shared decorations / field builders
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: const Color(0xFF141420),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.4),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ],
  );

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
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
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
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF4A4A5A)),
              prefixIcon: Icon(icon, color: const Color(0xFF6B6B80), size: 20),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
    String error = '',
    void Function(String)? onChange,
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
            obscureText: !visible,
            onChanged: onChange,
            style: const TextStyle(fontSize: 15, color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF4A4A5A)),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF6B6B80),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF6B6B80),
                  size: 20,
                ),
                onPressed: onToggle,
              ),
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
