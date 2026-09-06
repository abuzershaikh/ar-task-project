import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/profile_bloc.dart';
import '../../data/models/profile_model.dart';

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  String _selectedIndustry = 'E-Commerce & D2C';
  bool _initialized = false;

  final List<String> _industries = [
    'E-Commerce & D2C',
    'Mobile Apps & Gaming',
    'YouTube & Content Studio',
    'SaaS & Software Technology',
    'Marketing Agency',
    'Finance & Crypto',
    'EdTech & Education',
  ];

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController();
    _websiteController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initFields(ProfileModel profile) {
    if (_initialized) return;
    _companyController.text = profile.companyName;
    _websiteController.text = profile.website;
    _addressController.text = profile.billingAddress;
    if (_industries.contains(profile.industry)) {
      _selectedIndustry = profile.industry;
    }
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Business Profile',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading && !_initialized) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
          }

          final profile = state is ProfileLoaded
              ? state.profile
              : (state is ProfileUpdating ? state.currentProfile : null);

          if (profile != null) {
            _initFields(profile);
          }

          final isUpdating = state is ProfileUpdating || state is ProfileLoading;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                        const Color(0xFF4F46E5).withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business_center_rounded, color: Color(0xFF38BDF8), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Company & Brand Account',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Add your brand name and official address for commercial campaign management and verified invoices.',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF94A3B8),
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Company Name
                _buildLabel('Registered Company / Brand Name *'),
                const SizedBox(height: 6),
                _buildField(
                  controller: _companyController,
                  hint: 'e.g. Apex Marketing Private Limited',
                  icon: Icons.business_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
                ),
                const SizedBox(height: 18),

                // Industry Dropdown
                _buildLabel('Business Category / Industry'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedIndustry,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF38BDF8)),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5),
                      items: _industries.map((ind) {
                        return DropdownMenuItem<String>(
                          value: ind,
                          child: Row(
                            children: [
                              const Icon(Icons.category_outlined, color: Color(0xFF64748B), size: 16),
                              const SizedBox(width: 10),
                              Text(ind),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedIndustry = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Official Website
                _buildLabel('Official Website / App Link'),
                const SizedBox(height: 6),
                _buildField(
                  controller: _websiteController,
                  hint: 'https://yourbrand.com',
                  icon: Icons.language_rounded,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 18),

                // Billing Address
                _buildLabel('Official Billing Address'),
                const SizedBox(height: 6),
                _buildField(
                  controller: _addressController,
                  hint: 'Street address, Suite / Floor, City, State, PIN Code',
                  icon: Icons.location_city_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Submit Button
                GestureDetector(
                  onTap: isUpdating ? null : _saveBusinessProfile,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: isUpdating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Save Business Details',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: const Color(0xFF94A3B8),
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
      ),
    );
  }

  void _saveBusinessProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final data = {
        'companyName': _companyController.text.trim(),
        'industry': _selectedIndustry,
        'website': _websiteController.text.trim(),
        'billingAddress': _addressController.text.trim(),
      };
      context.read<ProfileBloc>().add(UpdateBusinessProfileEvent(data));
    }
  }
}
