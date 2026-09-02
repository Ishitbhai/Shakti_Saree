import 'package:flutter/material.dart';

import '../styles/app_colors.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: AppColors.muted,
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.arrow_back,
          color: AppColors.black,
          size: 22,
        ),
      ),
    );
  }
}