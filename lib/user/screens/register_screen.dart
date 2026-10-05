import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  // Validation error state variables
  String? _nameError;
  String? _emailError;
  String? _mobileError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Password Regex: >= 1 uppercase, >= 1 lowercase, >= 1 digit, >= 1 special char, min 6 characters
  final RegExp _passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&#^()_\-+={}\[\]:;"<>,./~`|\\])[A-Za-z\d@$!%*?&#^()_\-+={}\[\]:;"<>,./~`|\\]{6,}$',
  );

  // Exactly 10 digits
  final RegExp _mobileRegex = RegExp(r'^\d{10}$');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _nameError = null;
      _emailError = null;
      _mobileError = null;
      _passwordError = null;
      _confirmPasswordError = null;

      if (name.isEmpty) {
        _nameError = 'Please enter your full name';
      }

      if (email.isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!email.contains('@') || !email.contains('.')) {
        _emailError = 'Enter a valid email address';
      }

      if (mobile.isEmpty) {
        _mobileError = 'Please enter your mobile number';
      } else if (!_mobileRegex.hasMatch(mobile)) {
        _mobileError = 'Mobile number must be exactly 10 digits';
      }

      if (password.isEmpty) {
        _passwordError = 'Please enter your password';
      } else if (!_passwordRegex.hasMatch(password)) {
        _passwordError =
            'Must have 1 uppercase, 1 lowercase, 1 number, 1 special char & min 6 chars';
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordError = 'Please re-enter your password';
      } else if (password != confirmPassword) {
        _confirmPasswordError = 'Passwords do not match';
      }
    });

    if (_nameError == null &&
        _emailError == null &&
        _mobileError == null &&
        _passwordError == null &&
        _confirmPasswordError == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= FULL-WIDTH MAROON HEADER =================
            Container(
              width: double.infinity,
              color: AppColors.primary,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 24, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Arrow Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Title
                      Text(
                        'Create Account',
                        style: AppTextStyles.pageTitle.copyWith(
                          color: AppColors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        'Sign up',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= MAIN FORM CARD =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.black.withOpacity(0.75),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    _buildInputField(
                      label: 'Full Name',
                      hint: 'Enter Your Full Name',
                      icon: Icons.person_outline,
                      controller: _nameController,
                      errorText: _nameError,
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    // Email
                    _buildInputField(
                      label: 'Email',
                      hint: 'Enter Your Email Address',
                      icon: Icons.mail_outline,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      onChanged: (_) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    // Mobile Number
                    _buildInputField(
                      label: 'Mobile Number',
                      hint: '10-digit mobile number',
                      icon: Icons.phone_outlined,
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      errorText: _mobileError,
                      onChanged: (_) {
                        if (_mobileError != null) {
                          setState(() => _mobileError = null);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    // Password
                    _buildPasswordField(
                      label: 'Password',
                      hint: 'Create password',
                      controller: _passwordController,
                      isObscured: _isPasswordObscured,
                      errorText: _passwordError,
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                      onToggle: () {
                        setState(() {
                          _isPasswordObscured = !_isPasswordObscured;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    // Confirm Password
                    _buildPasswordField(
                      label: 'Confirm Password',
                      hint: 'Re-enter password',
                      controller: _confirmPasswordController,
                      isObscured: _isConfirmPasswordObscured,
                      errorText: _confirmPasswordError,
                      onChanged: (_) {
                        if (_confirmPasswordError != null) {
                          setState(() => _confirmPasswordError = null);
                        }
                      },
                      onToggle: () {
                        setState(() {
                          _isConfirmPasswordObscured =
                              !_isConfirmPasswordObscured;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleRegister,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ================= FOOTER =================
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: RichText(
                text: TextSpan(
                  text: 'Already registered? ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: 'Login',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ================= HELPER METHODS =================
  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorText != null
                  ? AppColors.primary
                  : AppColors.black.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppTextStyles.body,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.muted,
              ),
              prefixIcon: Icon(icon, color: AppColors.muted, size: 19),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback onToggle,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorText != null
                  ? AppColors.primary
                  : AppColors.black.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscured,
            style: AppTextStyles.body,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.muted,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.muted,
                size: 19,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.muted,
                  size: 19,
                ),
                onPressed: onToggle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
