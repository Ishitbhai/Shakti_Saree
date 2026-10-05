import 'package:flutter/material.dart';
import '../styles/app_colors.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AppBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.black.withOpacity(0.65),
            width: 1,
          ),
        ),
        child: const Icon(Icons.arrow_back, color: AppColors.black, size: 20),
      ),
    );
  }
}
