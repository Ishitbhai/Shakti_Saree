import 'package:flutter/material.dart';

import 'MainNavigationScreen.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _isUserLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 24,
                  ),
                  child: Column(
                    children: [
                      // Yellow emblem with "SS"
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: AppColors.yellowStatus,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'SS',
                            style: AppTextStyles.pageTitle.copyWith(
                              color: AppColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Title
                      Text(
                        'Shakti Saree',
                        style: AppTextStyles.pageTitle.copyWith(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        'Login to continue shopping',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

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
                    // ----- USER / ADMIN TOGGLE BOX -----
                    Container(
                      height: 52,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.black.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isUserLogin = true;
                                });
                              },
                              child: Container(
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: _isUserLogin
                                      ? Border.all(
                                          color: AppColors.primary.withOpacity(
                                            0.4,
                                          ),
                                          width: 1.2,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 18,
                                      color: _isUserLogin
                                          ? AppColors.primary
                                          : AppColors.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'User Login',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: _isUserLogin
                                            ? AppColors.primary
                                            : AppColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isUserLogin = false;
                                });
                              },
                              child: Container(
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: !_isUserLogin
                                      ? Border.all(
                                          color: AppColors.primary.withOpacity(
                                            0.4,
                                          ),
                                          width: 1.2,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      size: 18,
                                      color: !_isUserLogin
                                          ? AppColors.primary
                                          : AppColors.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Admin Login',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: !_isUserLogin
                                            ? AppColors.primary
                                            : AppColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ----- EMAIL FIELD -----
                    Text(
                      'Email',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
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
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: 'Enter Your Email Address',
                          hintStyle: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.muted,
                          ),
                          prefixIcon: const Icon(
                            Icons.mail_outline,
                            color: AppColors.muted,
                            size: 19,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ----- PASSWORD FIELD -----
                    Text(
                      'Password',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
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
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.muted,
                            letterSpacing: 2,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.muted,
                            size: 19,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.muted,
                              size: 19,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ----- LOGIN BUTTON -----
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MainNavigationScreen(initialIndex: 0),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Login',
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

            const SizedBox(height: 24),

            // ================= FOOTER =================
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              child: RichText(
                text: TextSpan(
                  text: 'New user? ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: 'Create an account',
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
}
