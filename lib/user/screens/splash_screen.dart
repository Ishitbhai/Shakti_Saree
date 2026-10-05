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
  // State variables for brand details and configuration[cite: 23]
  final String initials = 'SS';
  final String brandName = 'SHAKTI SAREE';
  final String brandTagline = 'Tradition Women With Elegance';
  final String footerText = 'MADE IN INDIA';
  final int splashDurationMs = 2500;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Navigate automatically after splash duration[cite: 23]
    _timer = Timer(Duration(milliseconds: splashDurationMs), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const LoginScreen(), // Replace with LoginScreen next[cite: 23]
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            // ================= PERFECT CENTER CONTENT =================[cite: 23]
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emblem Circle[cite: 23]
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.yellowStatus,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: AppTextStyles.pageTitle.copyWith(
                            color: AppColors.primary,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Brand Title[cite: 23]
                    Text(
                      brandName,
                      style: AppTextStyles.pageTitle.copyWith(
                        color: AppColors.white,
                        fontSize: 26,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Golden Divider Line[cite: 23]
                    Container(
                      width: 90,
                      height: 1.5,
                      color: AppColors.yellowStatus,
                    ),

                    const SizedBox(height: 14),

                    // Subtitle[cite: 23]
                    Text(
                      brandTagline,
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

            // ================= PINNED BOTTOM FOOTER =================[cite: 23]
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  footerText,
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
