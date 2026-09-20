import 'dart:async';
import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'login_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate automatically after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),// Replace with LoginScreen next
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            // ================= PERFECT CENTER CONTENT =================
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emblem Circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.yellowStatus,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'SS',
                          style: AppTextStyles.pageTitle.copyWith(
                            color: AppColors.primary,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Brand Title
                    Text(
                      'SHAKTI SAREE',
                      style: AppTextStyles.pageTitle.copyWith(
                        color: AppColors.white,
                        fontSize: 26,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Golden Divider Line
                    Container(
                      width: 90,
                      height: 1.5,
                      color: AppColors.yellowStatus,
                    ),

                    const SizedBox(height: 14),

                    // Subtitle
                    Text(
                      'Tradition Women With Elegance',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.yellowStatus,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= PINNED BOTTOM FOOTER =================
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'MADE IN INDIA',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
