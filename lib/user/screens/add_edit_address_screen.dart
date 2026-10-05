import 'package:flutter/material.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

class AddEditAddressScreen extends StatefulWidget {
  const AddEditAddressScreen({super.key});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  // 1. Text Controllers
  final TextEditingController _nameController = TextEditingController(
    text: 'Ishit Vadhavana',
  );
  final TextEditingController _addressController = TextEditingController(
    text: 'Samras Hostel, Rajkot',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '+91 12345 67890',
  );
  final TextEditingController _pincodeController = TextEditingController(
    text: '360002',
  );
  final TextEditingController _saveAsController = TextEditingController(
    text: 'Home',
  );

  // 2. Error Strings
  String errName = '';
  String errAddress = '';
  String errPhone = '';
  String errPincode = '';
  String errSaveAs = '';

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _saveAsController.dispose();
    super.dispose();
  }

  // Submit and Validation
  void validateAndSubmit() {
    setState(() {
      bool isValid = true;

      // Name Validation
      if (_nameController.text.trim().isEmpty) {
        errName = 'Your name is required';
        isValid = false;
      } else {
        errName = '';
      }

      // Address Validation
      if (_addressController.text.trim().isEmpty) {
        errAddress = 'Address is required';
        isValid = false;
      } else if (_addressController.text.trim().length < 8) {
        errAddress = 'Please enter a complete street address';
        isValid = false;
      } else {
        errAddress = '';
      }

      // Phone Validation
      String phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (phone.isEmpty) {
        errPhone = 'Mobile number is required';
        isValid = false;
      } else if (phone.length < 10) {
        errPhone = 'Enter a valid 10-digit mobile number';
        isValid = false;
      } else {
        errPhone = '';
      }

      // Pincode Validation
      String pin = _pincodeController.text.trim();
      final pinRegex = RegExp(r'^[1-9][0-9]{5}$');
      if (pin.isEmpty) {
        errPincode = 'Pincode is required';
        isValid = false;
      } else if (!pinRegex.hasMatch(pin)) {
        errPincode = 'Enter a valid 6-digit Indian pincode';
        isValid = false;
      } else {
        errPincode = '';
      }

      // Save as Validation
      if (_saveAsController.text.trim().isEmpty) {
        errSaveAs = 'Label is required (e.g. Home, Office)';
        isValid = false;
      } else {
        errSaveAs = '';
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
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: SizedBox(
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Add/Edit Address',
                      style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(),
                    ),
                  ],
                ),
              ),
            ),

            // ================= FORM BODY =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Your Name
                    _buildLabel('Your Name'),
                    const SizedBox(height: 6),
                    _buildInputField(
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

                    // Address
                    _buildLabel('Address'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _addressController,
                      icon: Icons.home_outlined,
                      hasError: errAddress.isNotEmpty,
                    ),
                    if (errAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        errAddress,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Mobile Number
                    _buildLabel('Mobile Number'),
                    const SizedBox(height: 6),
                    _buildInputField(
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

                    // Pincode
                    _buildLabel('Pincode'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _pincodeController,
                      icon: Icons.location_on_outlined,
                      keyboardType: TextInputType.number,
                      hasError: errPincode.isNotEmpty,
                    ),
                    if (errPincode.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        errPincode,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Save as
                    _buildLabel('Save as'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _saveAsController,
                      icon: Icons.save_outlined,
                      hasError: errSaveAs.isNotEmpty,
                    ),
                    if (errSaveAs.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        errSaveAs,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ],

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),

            // ================= PINNED SAVE CHANGES BUTTON =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
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

  Widget _buildInputField({
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
          width: hasError ? 1.2 : 1,
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
          prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
