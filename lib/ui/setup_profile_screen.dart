import 'package:flutter/material.dart';
import '../data/firebase_service.dart';
import '../data/hive_service.dart';
import 'home.dart'; // your HomePage (bottom nav shell)

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  int? _selectedAvatar; // null = default avatar
  bool _nameError = false;
  String _nameErrorText = '';
  bool _isSaving = false;

  static const Color _red = Color(0xFFE50914);
  static const Color _bg = Color(0xFF0A0A0F);
  static const Color _card = Color(0xFF141420);

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  String _avatarAsset(int? index) {
    if (index == null) return 'assets/images/avatar_null_profile_picture.png';
    return 'assets/images/avatar_profile_picture_$index.png';
  }

  bool _validate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = true;
        _nameErrorText = 'Display name is required';
      });
      return false;
    }
    if (name.length > 30) {
      setState(() {
        _nameError = true;
        _nameErrorText = 'Name cannot exceed 30 characters';
      });
      return false;
    }
    setState(() {
      _nameError = false;
      _nameErrorText = '';
    });
    return true;
  }

  Future<void> _onDone() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final avatarPath = _avatarAsset(_selectedAvatar);
    final email = FirebaseService.currentEmail ?? '';
    final uid = FirebaseService.currentUid;

    // 1. Save locally (fast, instant)
    await HiveService.saveProfile(
      name: name,
      email: email,
      avatarPath: avatarPath,
    );

    // 2. Save to Firestore (fire & forget)
    if (uid != null) {
      FirebaseService.saveUserProfile(
        uid: uid,
        name: name,
        avatarPath: avatarPath,
      ).catchError((e) => debugPrint('[SetupProfile] Firestore error: $e'));
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.movie_filter_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Setup Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Avatar picker
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showAvatarPicker,
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _red, width: 2.5),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      _avatarAsset(_selectedAvatar),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: _red,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: _red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _bg, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to choose avatar',
                            style: TextStyle(
                              color: Color(0xFF6B6B80),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Display Name
                    const Text(
                      'Display Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFFB0B0C0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _nameError
                              ? Colors.red.shade700
                              : const Color(0xFF2A2A3A),
                        ),
                      ),
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        maxLength: 30,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        onChanged: (_) {
                          if (_nameError) _validate();
                        },
                        decoration: const InputDecoration(
                          hintText: 'Your name',
                          hintStyle: TextStyle(color: Color(0xFF4A4A5A)),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Color(0xFF6B6B80),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    if (_nameError)
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
                              _nameErrorText,
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 15),

                    // Done button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _onDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          disabledBackgroundColor: _red.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141420),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Choose Avatar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  itemCount: 25,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (_, i) {
                    final idx = i == 0 ? null : i;
                    final path = _avatarAsset(idx);
                    final isSelected = _selectedAvatar == idx;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedAvatar = idx);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE50914)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Color(0xFFE50914),
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
