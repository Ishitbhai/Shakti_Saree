import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakti_saree/user/widgets/app_back_button.dart';

import '../../admin/data/firestore/firestore_schema.dart';
import '../../admin/data/providers/backend_providers.dart';
import '../data/shop_providers.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final String? addressId;
  final Map<String, dynamic>? initialAddressData;

  const AddEditAddressScreen({
    super.key,
    this.addressId,
    this.initialAddressData,
  });

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _saveAsController;

  String errName = '';
  String errAddress = '';
  String errPhone = '';
  String errPincode = '';
  String errSaveAs = '';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialAddressData ?? {};

    // Populates fields ONLY if editing existing address data, otherwise completely empty
    _nameController = TextEditingController(text: Fs.stringOf(d['recipient_name']));
    _addressController = TextEditingController(text: Fs.stringOf(d['street']));
    _phoneController = TextEditingController(text: Fs.stringOf(d['phone']));
    _pincodeController = TextEditingController(text: Fs.stringOf(d['pincode']));
    _saveAsController = TextEditingController(
      text: widget.initialAddressData != null ? Fs.stringOf(d['label']) : 'Home',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _saveAsController.dispose();
    super.dispose();
  }

  Future<void> validateAndSubmit() async {
    bool isValid = true;

    final nameTrimmed = _nameController.text.trim();
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (nameTrimmed.isEmpty) {
      errName = 'Your name is required';
      isValid = false;
    } else if (!nameRegex.hasMatch(nameTrimmed)) {
      errName = 'Name must contain only letters and spaces';
      isValid = false;
    } else {
      errName = '';
    }

    final addressTrimmed = _addressController.text.trim();
    if (addressTrimmed.isEmpty) {
      errAddress = 'Address is required';
      isValid = false;
    } else if (addressTrimmed.length < 8) {
      errAddress = 'Please enter a complete street address';
      isValid = false;
    } else {
      errAddress = '';
    }

    final phoneTrimmed = _phoneController.text.trim();
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (phoneTrimmed.isEmpty) {
      errPhone = 'Mobile number is required';
      isValid = false;
    } else if (!phoneRegex.hasMatch(phoneTrimmed)) {
      errPhone = 'Enter a valid 10-digit mobile number';
      isValid = false;
    } else {
      errPhone = '';
    }

    final pinTrimmed = _pincodeController.text.trim();
    final pinRegex = RegExp(r'^[1-9][0-9]{5}$');
    if (pinTrimmed.isEmpty) {
      errPincode = 'Pincode is required';
      isValid = false;
    } else if (!pinRegex.hasMatch(pinTrimmed)) {
      errPincode = 'Enter a valid 6-digit Indian pincode';
      isValid = false;
    } else {
      errPincode = '';
    }

    final saveAsTrimmed = _saveAsController.text.trim();
    final saveAsRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (saveAsTrimmed.isEmpty) {
      errSaveAs = 'Label is required (e.g. Home, Office)';
      isValid = false;
    } else if (!saveAsRegex.hasMatch(saveAsTrimmed)) {
      errSaveAs = 'Label must contain only letters';
      isValid = false;
    } else {
      errSaveAs = '';
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
      final formattedString = '$addressTrimmed, Pincode: $pinTrimmed';
      final addressData = {
        'recipient_name': nameTrimmed,
        'phone': phoneTrimmed,
        'street': addressTrimmed,
        'pincode': pinTrimmed,
        'label': saveAsTrimmed,
        'updated_at': FieldValue.serverTimestamp(),
      };

      final addressesCollection = db
          .collection(Fs.users)
          .doc(uid)
          .collection('addresses');

      if (widget.addressId != null) {
        await addressesCollection.doc(widget.addressId).set(addressData, SetOptions(merge: true));
      } else {
        await addressesCollection.add({
          ...addressData,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      await db.collection(Fs.users).doc(uid).set({
        Fs.address: formattedString,
        'street': addressTrimmed,
        'pincode': pinTrimmed,
        'address_label': saveAsTrimmed,
        'delivery_address': addressData,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.addressId != null
                  ? 'Address updated successfully!'
                  : 'New address added successfully!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.addressId != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: SizedBox(
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      isEditing ? 'Edit Address' : 'Add New Address',
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Your Name'),
                    const SizedBox(height: 6),
                    _buildInputField(
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

                    _buildLabel('Street Address / Building'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _addressController,
                      icon: Icons.home_outlined,
                      keyboardType: TextInputType.streetAddress,
                      hasError: errAddress.isNotEmpty,
                    ),
                    if (errAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(errAddress, style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ],

                    const SizedBox(height: 16),

                    _buildLabel('Mobile Number'),
                    const SizedBox(height: 6),
                    _buildInputField(
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

                    _buildLabel('Pincode'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _pincodeController,
                      icon: Icons.location_on_outlined,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      hasError: errPincode.isNotEmpty,
                    ),
                    if (errPincode.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(errPincode, style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ],

                    const SizedBox(height: 16),

                    _buildLabel('Save as (e.g. Home, Office)'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _saveAsController,
                      icon: Icons.save_outlined,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      ],
                      hasError: errSaveAs.isNotEmpty,
                    ),
                    if (errSaveAs.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(errSaveAs, style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ],

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
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
                          isEditing ? 'Update Address' : 'Save Address',
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
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
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
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
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