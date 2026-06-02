import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;

  String _currentPassError = '';
  String _newPassError = '';
  String _confirmPassError = '';
  String _generalError = '';

  int _passwordStrength = 0;
  String _strengthLabel = '';

  bool _isLoading = false;
  bool _isSuccess = false;

  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _bg = Color(0xFF0A0A0F);
  static const Color _card = Color(0xFF141420);

  bool get _canSubmit =>
      _currentPassController.text.isNotEmpty &&
      _newPassController.text.isNotEmpty &&
      _confirmPassController.text.isNotEmpty;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  //  Password strength
  int _calcStrength(String p) {
    int s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) s++;
    return s;
  }

  void _onNewPasswordChanged(String value) {
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
      if (_newPassError.isNotEmpty) _newPassError = '';
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

  Color get _strengthTextColor {
    if (_passwordStrength <= 1) return Colors.red;
    if (_passwordStrength == 2) return Colors.orange;
    return Colors.green;
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _currentPassError = '';
      _newPassError = '';
      _confirmPassError = '';
      _generalError = '';
    });

    if (_currentPassController.text.isEmpty) {
      setState(() => _currentPassError = 'Current password is required');
      valid = false;
    }

    final newPass = _newPassController.text;
    if (newPass.isEmpty) {
      setState(() => _newPassError = 'New password is required');
      valid = false;
    } else if (newPass.length < 6) {
      setState(() => _newPassError = 'Minimum 6 characters');
      valid = false;
    } else if (newPass == _currentPassController.text) {
      setState(() => _newPassError = 'Enter a new password');
      valid = false;
    }

    if (_confirmPassController.text != newPass) {
      setState(() => _confirmPassError = 'Passwords do not match');
      valid = false;
    }

    return valid;
  }

  Future<void> _onChangePassword() async {
    if (!_validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _generalError = '';
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _generalError = 'No user found. Please log in again.';
      });
      return;
    }

    // 1. Re-authenticate
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPassController.text,
      );
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _currentPassError = 'Incorrect password';
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

    // 2. Update password
    try {
      await user.updatePassword(_newPassController.text);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'weak-password') {
          _newPassError = 'Password is too weak. Use at least 6 characters.';
        } else {
          _generalError = 'Could not update password. Please try again.';
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
      _isSuccess = true;
    });
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

                  if (_isSuccess)
                    _buildSuccessCard()
                  else ...[
                    _buildInfoBanner(),
                    const SizedBox(height: 24),
                    _buildForm(),
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
            'Change Password',
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
          Icon(Icons.shield_outlined, color: _purple, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your session will stay active after changing your password.',
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
          // Current password
          _label('Current Password'),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _currentPassController,
            hint: '••••••••',
            visible: _currentVisible,
            error: _currentPassError,
            onToggle: () => setState(() => _currentVisible = !_currentVisible),
            onChanged: (_) {
              if (_currentPassError.isNotEmpty) {
                setState(() => _currentPassError = '');
              }
              setState(() {});
            },
          ),

          const SizedBox(height: 20),

          // New password
          _label('New Password'),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _newPassController,
            hint: '••••••••',
            visible: _newVisible,
            error: _newPassError,
            onToggle: () => setState(() => _newVisible = !_newVisible),
            onChanged: (val) {
              _onNewPasswordChanged(val);
              setState(() {});
            },
          ),

          // Strength bar
          if (_newPassController.text.isNotEmpty) ...[
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
              style: TextStyle(fontSize: 11, color: _strengthTextColor),
            ),
          ],

          const SizedBox(height: 20),

          // Confirm new password
          _label('Confirm New Password'),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _confirmPassController,
            hint: '••••••••',
            visible: _confirmVisible,
            error: _confirmPassError,
            onToggle: () => setState(() => _confirmVisible = !_confirmVisible),
            onChanged: (_) {
              if (_confirmPassError.isNotEmpty) {
                setState(() => _confirmPassError = '');
              }
              setState(() {});
            },
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
              onPressed: (_isLoading || !_canSubmit) ? null : _onChangePassword,
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
                      'Update Password',
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

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
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
              Icons.lock_open_rounded,
              color: Color(0xFF10B981),
              size: 38,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Password Changed!',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your password has been updated successfully.\nYou can continue using the app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Done',
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
    String error = '',
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
            obscureText: !visible,
            onChanged: onChanged,
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
}
