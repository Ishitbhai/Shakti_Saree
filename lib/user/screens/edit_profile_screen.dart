import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../admin/data/firestore/firestore_schema.dart';
import '../../admin/data/providers/backend_providers.dart';
import '../data/shop_providers.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  const EditProfileScreen({super.key, this.initialData});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dobController;

  bool _isSaving = false;
  DateTime _selectedDate = DateTime(2007, 3, 22);
  String _selectedGender = 'Male';

  String errName = '';
  String errPhone = '';
  String errDob = '';

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData ?? {};
    _nameController = TextEditingController(text: Fs.stringOf(d[Fs.name]));
    _emailController = TextEditingController(text: Fs.stringOf(d[Fs.email]));
    _phoneController = TextEditingController(text: Fs.stringOf(d[Fs.phone]));
    _dobController = TextEditingController(
      text: Fs.stringOf(d['dob']).isEmpty ? '22 Mar 2007' : Fs.stringOf(d['dob']),
    );
    _selectedGender = Fs.stringOf(d['gender']).isEmpty ? 'Male' : Fs.stringOf(d['gender']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')} ${_months[picked.month - 1]} ${picked.year}';
        errDob = '';
      });
    }
  }

  Future<void> validateAndSubmit() async {
    bool isValid = true;
    final nameTrimmed = _nameController.text.trim();
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');

    // 1. Name: Letters and spaces only
    if (nameTrimmed.isEmpty) {
      errName = 'Name is required';
      isValid = false;
    } else if (!nameRegex.hasMatch(nameTrimmed)) {
      errName = 'Name must contain only letters and spaces';
      isValid = false;
    } else {
      errName = '';
    }

    // 2. Mobile: Exactly 10 digits starting with Indian operator prefixes (6-9)
    final phoneDigits = _phoneController.text.trim();
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');

    if (phoneDigits.isEmpty) {
      errPhone = 'Mobile number is required';
      isValid = false;
    } else if (!phoneRegex.hasMatch(phoneDigits)) {
      errPhone = 'Enter a valid 10-digit mobile number';
      isValid = false;
    } else {
      errPhone = '';
    }

    // 3. Date of Birth
    if (_dobController.text.trim().isEmpty) {
      errDob = 'Please select Date of Birth';
      isValid = false;
    } else {
      errDob = '';
    }

    setState(() {});
    if (!isValid) return;

    final uid = ref.read(customerUidProvider);
    final db = ref.read(firestoreProvider);

    if (uid == null || db == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No active user session.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await db.collection(Fs.users).doc(uid).set({
        Fs.name: nameTrimmed,
        Fs.phone: phoneDigits,
        'dob': _dobController.text.trim(),
        'gender': _selectedGender,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= HEADER WITH AVATAR =================
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: double.infinity,
                  height: 170,
                  color: AppColors.primary,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 24),
                            ),
                          ),
                          Text(
                            'Edit Profile',
                            style: AppTextStyles.pageTitle.copyWith(
                              color: AppColors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -46,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()[0].toUpperCase()
                            : 'IV',
                        style: AppTextStyles.pageTitle.copyWith(
                          color: AppColors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // ================= FORM FIELDS =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Full Name'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _nameController,
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    hasError: errName.isNotEmpty,
                  ),
                  if (errName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(errName, style: const TextStyle(color: Colors.red, fontSize: 11)),
                  ],

                  const SizedBox(height: 16),

                  _buildLabel('Email Address (Read Only)'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _emailController,
                    icon: Icons.mail_outline,
                    enabled: false,
                  ),

                  const SizedBox(height: 16),

                  _buildLabel('Mobile Number'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    hasError: errPhone.isNotEmpty,
                  ),
                  if (errPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(errPhone, style: const TextStyle(color: Colors.red, fontSize: 11)),
                  ],

                  const SizedBox(height: 16),

                  _buildLabel('Date of Birth'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: errDob.isNotEmpty ? Colors.red : AppColors.black.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: AppColors.muted, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _dobController.text,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: AppColors.muted, size: 22),
                        ],
                      ),
                    ),
                  ),
                  if (errDob.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(errDob, style: const TextStyle(color: Colors.red, fontSize: 11)),
                  ],

                  const SizedBox(height: 16),

                  _buildLabel('Gender'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildGenderOption('Male')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildGenderOption('Female')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildGenderOption('Other')),
                    ],
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : validateAndSubmit,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.label.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool hasError = false,
    bool enabled = true,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: enabled ? AppColors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? Colors.red : AppColors.black.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        style: AppTextStyles.body.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.muted, size: 19),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender) {
    final bool isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedGender = gender);
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.black.withOpacity(0.4),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          gender,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? AppColors.white : AppColors.muted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}