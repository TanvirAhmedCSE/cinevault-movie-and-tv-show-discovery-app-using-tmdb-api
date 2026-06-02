import 'package:flutter/material.dart';
import '../../data/firebase_service.dart';
import '../../data/hive_service.dart';

class ChangePersonalDetailsScreen extends StatefulWidget {
  const ChangePersonalDetailsScreen({super.key});

  @override
  State<ChangePersonalDetailsScreen> createState() =>
      _ChangePersonalDetailsScreenState();
}

class _ChangePersonalDetailsScreenState
    extends State<ChangePersonalDetailsScreen> {
  late final TextEditingController _nameController;
  final _nameFocus = FocusNode();

  // Track original values
  late String _originalName;
  late String _originalAvatarPath;

  // Current selected avatar (index)
  int? _selectedAvatar;
  bool _nameError = false;
  String _nameErrorText = '';
  bool _isSaving = false;
  String _feedbackMessage = '';
  bool _feedbackIsError = false;

  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _bg = Color(0xFF0A0A0F);
  static const Color _card = Color(0xFF141420);

  @override
  void initState() {
    super.initState();
    _originalName = HiveService.name;
    _originalAvatarPath = HiveService.avatarPath;

    _nameController = TextEditingController(text: _originalName);

    // Parse current avatar index from path
    _selectedAvatar = _parseAvatarIndex(_originalAvatarPath);
  }

  int? _parseAvatarIndex(String path) {
    final regex = RegExp(r'avatar_profile_picture_(\d+)\.png');
    final match = regex.firstMatch(path);
    if (match != null) return int.tryParse(match.group(1)!);
    return null; // null = default
  }

  String _avatarAsset(int? index) {
    if (index == null) return 'assets/images/avatar_null_profile_picture.png';
    return 'assets/images/avatar_profile_picture_$index.png';
  }

  String get _currentAvatarPath => _avatarAsset(_selectedAvatar);

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

  Future<void> _onSave() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_validate()) return;

    setState(() {
      _isSaving = true;
      _feedbackMessage = '';
    });

    final trimmedName = _nameController.text.trim();
    final newAvatarPath = _currentAvatarPath;

    final sameName = trimmedName == _originalName;
    final sameAvatar = newAvatarPath == _originalAvatarPath;

    // Simulate a brief check delay for UX (spinner shows)
    await Future.delayed(const Duration(milliseconds: 600));

    if (sameName && sameAvatar) {
      setState(() {
        _isSaving = false;
        _feedbackMessage =
            'You have given the same name and same profile image.';
        _feedbackIsError = true;
      });
      return;
    }

    // Perform updates
    final uid = FirebaseService.currentUid;
    final email = FirebaseService.currentEmail ?? HiveService.email;

    // Save to Hive immediately
    await HiveService.saveProfile(
      name: trimmedName,
      email: email,
      avatarPath: newAvatarPath,
    );

    // Save to Firestore (fire & forget)
    if (uid != null) {
      FirebaseService.saveUserProfile(
        uid: uid,
        name: trimmedName,
        avatarPath: newAvatarPath,
      ).catchError((e) => debugPrint('[ChangePersonalDetails] Firestore: $e'));
    }

    // Update originals so subsequent saves compare correctly
    _originalName = trimmedName;
    _originalAvatarPath = newAvatarPath;

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _feedbackMessage = 'Profile updated successfully!';
      _feedbackIsError = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
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
                  const SizedBox(height: 32),

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
                                  border: Border.all(
                                    color: _purple,
                                    width: 2.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    _currentAvatarPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: _purple,
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
                                    color: _purple,
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
                          'Tap to change avatar',
                          style: TextStyle(
                            color: Color(0xFF6B6B80),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Name label
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
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                      onChanged: (_) {
                        if (_nameError) _validate();
                        setState(() {
                          _feedbackMessage = '';
                        });
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

                  // Feedback message
                  if (_feedbackMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _feedbackIsError
                        ? _buildFeedback(
                            message: _feedbackMessage,
                            isError: true,
                          )
                        : _buildFeedback(
                            message: _feedbackMessage,
                            isError: false,
                          ),
                  ],

                  const SizedBox(height: 15),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isSaving) ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        disabledBackgroundColor: _purple.withValues(
                          alpha: 0.35,
                        ),
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
                              'Save Changes',
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
            'Personal Details',
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

  Widget _buildFeedback({required String message, required bool isError}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.shade900.withValues(alpha: 0.25)
            : const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? Colors.red.shade800
              : const Color(0xFF10B981).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.info_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: isError ? Colors.red.shade400 : const Color(0xFF10B981),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red.shade300 : const Color(0xFF6EE7B7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
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
                        setState(() {
                          _selectedAvatar = idx;
                          _feedbackMessage = '';
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? _purple : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: _purple,
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
