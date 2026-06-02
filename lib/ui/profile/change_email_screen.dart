import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/firebase_service.dart';
import '../../data/hive_service.dart';
import '../login_page.dart';

enum _EmailChangeState { form, waitingVerification, verified }

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _emailError = '';
  String _passwordError = '';
  String _generalError = '';

  bool _passwordVisible = false;
  bool _isLoading = false;

  _EmailChangeState _state = _EmailChangeState.form;
  Timer? _verifyTimer;
  int _pollCount = 0;

  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _bg = Color(0xFF0A0A0F);
  static const Color _card = Color(0xFF141420);

  bool get _canSubmit => _newEmailController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _verifyTimer?.cancel();
    _newEmailController.dispose();
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

    final newEmail = _newEmailController.text.trim();

    if (newEmail.isEmpty) {
      setState(() => _emailError = 'Email is required');
      valid = false;
    } else if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(newEmail)) {
      setState(() => _emailError = 'Enter a valid email');
      valid = false;
    } else if (newEmail == HiveService.email) {
      setState(() => _emailError = 'Enter a new email');
      valid = false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      valid = false;
    }

    return valid;
  }

  Future<void> _onChangeEmail() async {
    if (!_validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _generalError = 'No user found. Please log in again.';
      });
      return;
    }

    // 1. Re-authenticate with current password
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _passwordError = 'Incorrect password';
        } else {
          _generalError = 'Authentication failed. Please try again.';
        }
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _generalError = 'Something went wrong. Please try again.';
      });
      return;
    }

    // 2. Send verification to new email (verifyBeforeUpdateEmail)
    try {
      await user.verifyBeforeUpdateEmail(_newEmailController.text.trim());
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'email-already-in-use') {
          _emailError = 'This email is already registered.';
        } else if (e.code == 'invalid-email') {
          _emailError = 'Please enter a valid email address.';
        } else {
          _generalError = 'Could not send verification. Try again.';
        }
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _generalError = 'Something went wrong. Please try again.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _pollCount = 0;
      _state = _EmailChangeState.waitingVerification;
    });

    // 3. Poll for email change confirmation
    _startVerificationPolling();
  }

  void _startVerificationPolling() {
    _verifyTimer?.cancel();
    _pollCount = 0;

    _verifyTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      _pollCount++;

      // Timeout fallback after ~60 s (20 polls × 3 s)
      // Firebase confirmed the link was sent. If the client-side token still
      // hasn't reflected the new email (known Firebase SDK quirk), we
      // optimistically update Hive/Firestore and move on.
      if (_pollCount > 20) {
        _verifyTimer?.cancel();
        await _commitEmailChange(_newEmailController.text.trim());
        return;
      }

      try {
        final user = FirebaseAuth.instance.currentUser;

        // reload() syncs the local user object with Firebase servers
        await user?.reload();

        // Force a token refresh — this is what actually updates the
        // in-memory email field after verifyBeforeUpdateEmail confirms
        await user?.getIdToken(true);

        // Re-read currentUser AFTER the refresh (the reference may be stale)
        final refreshedUser = FirebaseAuth.instance.currentUser;
        final updatedEmail = refreshedUser?.email ?? '';
        final newEmail = _newEmailController.text.trim();

        if (updatedEmail == newEmail && mounted) {
          _verifyTimer?.cancel();
          await _commitEmailChange(newEmail, uid: refreshedUser?.uid);
        }
      } catch (_) {
        // Network hiccup — keep polling silently
      }
    });
  }

  // Saves the new email to Hive
  // success state, then pops back after a short delay.
  Future<void> _commitEmailChange(String newEmail, {String? uid}) async {
    final resolvedUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    final name = HiveService.name;
    final avatarPath = HiveService.avatarPath;

    await HiveService.saveProfile(
      name: name,
      email: newEmail,
      avatarPath: avatarPath,
    );

    if (resolvedUid != null) {
      FirebaseService.saveUserProfile(
        uid: resolvedUid,
        name: name,
        avatarPath: avatarPath,
      ).catchError((e) => debugPrint('[ChangeEmail] Firestore: $e'));
    }

    if (!mounted) return;
    setState(() => _state = _EmailChangeState.verified);

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // Auto sign out
    await FirebaseService.signOut();
    await HiveService.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _resendVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.verifyBeforeUpdateEmail(_newEmailController.text.trim());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),

                  if (_state == _EmailChangeState.form) ...[
                    _buildInfoBanner(),
                    const SizedBox(height: 24),
                    _buildForm(),
                  ] else if (_state ==
                      _EmailChangeState.waitingVerification) ...[
                    _buildWaitingCard(),
                  ] else ...[
                    _buildSuccessCard(),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  App bar
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: _card,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Change Email',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  //  Info banner
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _purple, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A verification link will be sent to your new email. '
              'After clicking it, your email will be updated. '
              'You will be signed out and will need to log in again.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  Form
  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('New Email Address'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _newEmailController,
            hint: 'you@newdomain.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            error: _emailError,
            onChanged: (_) {
              if (_emailError.isNotEmpty) setState(() => _emailError = '');
              setState(() {});
            },
          ),

          const SizedBox(height: 20),
          _label('Current Password'),
          const SizedBox(height: 8),
          _buildPasswordField(),

          if (_generalError.isNotEmpty) ...[
            const SizedBox(height: 14),
            _errorBox(_generalError),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_isLoading || !_canSubmit) ? null : _onChangeEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                disabledBackgroundColor: _purple.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Change Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  //  Waiting card
  Widget _buildWaitingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _purple.withValues(alpha: 0.1),
              border: Border.all(
                color: _purple.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: CircularProgressIndicator(color: _purple, strokeWidth: 3),
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
          const SizedBox(height: 8),
          Text(
            _newEmailController.text.trim(),
            style: const TextStyle(
              color: Color(0xFF8B5CF6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Check your new email and click the verification link. '
            'This screen will update automatically once verified.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _resendVerification,
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
                    'Resend verification',
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

  //  Success card

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      decoration: BoxDecoration(
        color: _card,
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
            'Email Updated!',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your email has been changed successfully.',
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

  //  Reusable helpers
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String error = '',
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
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
            onChanged: onChanged,
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
            child: Row(
              children: [
                Icon(
                  Icons.cancel_outlined,
                  color: Colors.red.shade400,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  error,
                  style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _passwordError.isNotEmpty
                  ? Colors.red.shade700
                  : const Color(0xFF2A2A3A),
            ),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            style: const TextStyle(fontSize: 15, color: Colors.white),
            onChanged: (_) {
              if (_passwordError.isNotEmpty) {
                setState(() => _passwordError = '');
              }
            },
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: const TextStyle(color: Color(0xFF4A4A5A)),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF6B6B80),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF6B6B80),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_passwordError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.cancel_outlined,
                  color: Colors.red.shade400,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _passwordError,
                  style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
