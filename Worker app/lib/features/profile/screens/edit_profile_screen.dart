import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/profile_provider.dart';

/// 🌿 Emerald Jungle Themed Edit Profile Screen:
/// - Editable: Name, Mobile Number, Age.
/// - Autofetched & Readonly: Email.
/// - Mayan Emerald & Gold Palette with glowing inputs and glass cards.
class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialMobile;
  final String initialAge;
  final String initialEmail;

  const EditProfileScreen({
    super.key,
    this.initialName = 'Worker Pro',
    this.initialMobile = '+91 ••••• •••••',
    this.initialAge = '24',
    this.initialEmail = 'worker@taskpost.com',
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  bool _isSaving = false;

  // ── Palette Tokens ────────────────────────────────────────────────────────
  static const Color _bgDark = Color(0xFF04140F);
  static const Color _cardDark = Color(0xFF09291E);
  static const Color _cardBorder = Color(0xFF10B981);
  static const Color _goldPrimary = Color(0xFFF59E0B);
  static const Color _goldLight = Color(0xFFFDE68A);
  static const Color _emeraldBright = Color(0xFF10B981);
  static const Color _emeraldLight = Color(0xFF34D399);
  static const Color _textWhite = Color(0xFFF8FAFC);
  static const Color _textMuted = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _mobileController = TextEditingController(text: widget.initialMobile);
    _ageController = TextEditingController(text: widget.initialAge);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    setState(() => _isSaving = true);
    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile({
      'name': _nameController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully!',
            style: GoogleFonts.poppins(color: _bgDark, fontWeight: FontWeight.w600),
          ),
          backgroundColor: _emeraldBright,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile. Please try again.',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cardDark,
              border: Border.all(color: _cardBorder.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _textWhite, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Profile Details',
          style: GoogleFonts.poppins(
            color: _textWhite,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF04140F),
              Color(0xFF07241A),
              Color(0xFF03160F),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glowing Avatar Header
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_emeraldBright, _goldPrimary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _emeraldBright.withValues(alpha: 0.35),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF062016),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 54,
                            color: _goldLight,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _goldPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: _bgDark, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: _goldPrimary.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _cardDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _cardBorder.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Full Name
                      _buildFieldLabel('Full Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.poppins(
                          color: _textWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Enter your full name',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Field 2: Mobile Number
                      _buildFieldLabel('Mobile Number'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.poppins(
                          color: _textWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Enter mobile number',
                          icon: Icons.phone_android_rounded,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Field 3: Age
                      _buildFieldLabel('Age'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          color: _textWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Enter your age',
                          icon: Icons.cake_outlined,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Field 4: Email (Readonly)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldLabel('Email Address'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _cardBorder.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _cardBorder.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded, size: 11, color: _emeraldLight),
                                const SizedBox(width: 4),
                                Text(
                                  'Google Linked',
                                  style: GoogleFonts.poppins(
                                    color: _emeraldLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        enabled: false,
                        style: GoogleFonts.poppins(
                          color: _textMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Autofetched Email',
                          icon: Icons.email_outlined,
                          isReadOnly: true,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Save CTA Button
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [_emeraldBright, Color(0xFF059669)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _emeraldBright.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Save Profile Changes',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        color: _goldLight,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool isReadOnly = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: _textMuted.withValues(alpha: 0.6), fontSize: 13),
      prefixIcon: Icon(
        icon,
        size: 19,
        color: isReadOnly ? _textMuted : _emeraldLight,
      ),
      filled: true,
      fillColor: isReadOnly ? const Color(0xFF061E16) : const Color(0xFF0C3829),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _cardBorder.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _cardBorder.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _emeraldBright, width: 1.5),
      ),
    );
  }
}
