import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // 1. Text Controllers
  final TextEditingController _nameController = TextEditingController(
    text: 'Ishit Vadhavana',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'ishit@gmail.com',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '+91 12345 67890',
  );
  final TextEditingController _dobController = TextEditingController(
    text: '22 Mar 2007',
  );

  // 2. Form Variables
  DateTime _selectedDate = DateTime(2007, 3, 22);
  String _selectedGender = 'Male';
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // 3. Error Strings
  String errName = '';
  String errEmail = '';
  String errPhone = '';
  String errDob = '';
  String errGender = '';

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
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
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')} ${_months[picked.month - 1]} ${picked.year}';
        errDob = '';
      });
    }
  }

  // Submit and Validation
  void validateAndSubmit() {
    setState(() {
      bool isValid = true;

      // Name Validation
      if (_nameController.text.trim().isEmpty) {
        errName = 'Name is required';
        isValid = false;
      } else {
        errName = '';
      }

      // Email Validation
      String email = _emailController.text.trim();
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (email.isEmpty) {
        errEmail = 'Email is required';
        isValid = false;
      } else if (!emailRegex.hasMatch(email)) {
        errEmail = 'Enter a valid email';
        isValid = false;
      } else {
        errEmail = '';
      }

      // Phone Validation
      String phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (phone.isEmpty) {
        errPhone = 'Phone number is required';
        isValid = false;
      } else if (phone.length < 10) {
        errPhone = 'Enter a valid 10-digit number';
        isValid = false;
      } else {
        errPhone = '';
      }

      // Date of Birth Validation
      if (_dobController.text.trim().isEmpty) {
        errDob = 'Please select Date of Birth';
        isValid = false;
      } else {
        errDob = '';
      }

      // Gender Validation
      if (_selectedGender.isEmpty) {
        errGender = 'Please select gender';
        isValid = false;
      } else {
        errGender = '';
      }

      if (isValid) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= HEADER WITH OVERLAPPING AVATAR =================
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppColors.white,
                                size: 24,
                              ),
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

                // Avatar
                Positioned(
                  bottom: -46,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: _profileImage != null
                                ? Image.file(
                                    _profileImage!,
                                    fit: BoxFit.cover,
                                    width: 92,
                                    height: 92,
                                  )
                                : Center(
                                    child: Text(
                                      'IV',
                                      style: AppTextStyles.pageTitle.copyWith(
                                        color: AppColors.black,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 56),

            GestureDetector(
              onTap: _pickImage,
              child: Text(
                'Change Photo',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 24),

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
                    hasError: errName.isNotEmpty,
                  ),
                  if (errName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      errName,
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ],

                  const SizedBox(height: 16),

                  _buildLabel('Email Address'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _emailController,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    hasError: errEmail.isNotEmpty,
                  ),
                  if (errEmail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      errEmail,
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ],

                  const SizedBox(height: 16),

                  _buildLabel('Mobile Number'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    hasError: errPhone.isNotEmpty,
                  ),
                  if (errPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      errPhone,
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Date of Birth with Date Picker
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
                          color: errDob.isNotEmpty
                              ? Colors.red
                              : AppColors.black.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.muted,
                            size: 18,
                          ),
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
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.muted,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (errDob.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      errDob,
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Gender
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
                  if (errGender.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      errGender,
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: validateAndSubmit,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
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

                  // Cancel Link
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

  // ================= HELPER WIDGETS =================
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
    bool hasError = false,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? Colors.red : AppColors.black.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
        setState(() {
          _selectedGender = gender;
          errGender = '';
        });
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.black.withOpacity(0.4),
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
