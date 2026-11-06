import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/data/providers/backend_providers.dart';
import '../../admin/data/providers/session_providers.dart';
import '../../admin/screens/admin_shell.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'MainNavigationScreen.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // State variables for brand details and configuration[cite: 23]
  final String initials = 'SS';
  final String brandName = 'SHAKTI SAREE';
  final String brandTagline = 'Tradition Women With Elegance';
  final String footerText = 'MADE IN INDIA';
  final int splashDurationMs = 2500;

  // Firestore answers from its cache within about ten seconds when offline;
  // past this, something is stuck and the app should not sit on the splash
  static const Duration restoreTimeout = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _openStartScreen();
  }

  // Navigate automatically after splash duration[cite: 23]
  Future<void> _openStartScreen() async {
    final (screen, _) = await (
      _screenForSession(),
      Future<void>.delayed(Duration(milliseconds: splashDurationMs)),
    ).wait;
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // Where this launch opens, for whoever Firebase kept signed in. Their users
  // document decides, exactly as it does at login: an admin goes to the panel
  // and anyone else to the shop. If the role cannot be checked the session is
  // left alone for the next launch to try again, and they get the login screen
  // rather than a guess that could open the wrong side.
  Future<Widget> _screenForSession() async {
    final auth = ref.read(firebaseAuthProvider);
    final admins = ref.read(adminAuthRepositoryProvider);
    if (auth == null || admins == null) return const LoginScreen();

    try {
      final user = await auth.authStateChanges().first.timeout(restoreTimeout);
      if (user == null) return const LoginScreen();

      final session = await admins.sessionFor(user).timeout(restoreTimeout);
      if (session == null) return const MainNavigationScreen(initialIndex: 0);
      if (!mounted) return const LoginScreen();

      ref.read(adminSessionProvider.notifier).start(session);
      return const AdminShell();
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not verify your account. Check your connection and '
              'login again.',
            ),
          ),
        );
      }
      return const LoginScreen();
    }
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
