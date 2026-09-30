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
  final TextEditingController _nameController =
      TextEditingController(text: 'Ishit Vadhavana');
  final TextEditingController _addressController =
      TextEditingController(text: 'Samras Hostel, Rajkot');
  final TextEditingController _phoneController =
      TextEditingController(text: '+91 12345 67890');
  final TextEditingController _pincodeController =
      TextEditingController(text: '360002');
  final TextEditingController _saveAsController =
      TextEditingController(text: 'Home');

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _saveAsController.dispose();
    super.dispose();
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Your Name
                    _buildLabel('Your Name'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _nameController,
                      icon: Icons.person_outline,
                    ),

                    const SizedBox(height: 16),

                    // Address
                    _buildLabel('Address'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _addressController,
                      icon: Icons.home_outlined,
                    ),

                    const SizedBox(height: 16),

                    // Mobile Number
                    _buildLabel('Mobile Number'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),

                    // Pincode
                    _buildLabel('Pincode'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _pincodeController,
                      icon: Icons.location_on_outlined,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    // Save as
                    _buildLabel('Save as'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _saveAsController,
                      icon: Icons.save_outlined,
                    ),

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
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.black.withOpacity(0.6),
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
          prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}