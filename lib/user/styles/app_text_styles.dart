import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  // Lora Bold
  static TextStyle pageTitle = GoogleFonts.lora(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static TextStyle sectionTitle = GoogleFonts.lora(
    fontSize: 13.5,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static TextStyle faqTitle = GoogleFonts.lora(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static TextStyle successTitle = GoogleFonts.lora(
    fontSize: 27,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  // Poppins Regular
  static TextStyle body = GoogleFonts.poppins(
    fontSize: 12.5,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
  );

  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 9.5,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
  );

  static TextStyle label = GoogleFonts.poppins(
    fontSize: 11.5,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
  );

  // Poppins Bold
  static TextStyle button = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static TextStyle payNow = GoogleFonts.poppins(
    fontSize: 14.5,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static TextStyle action = GoogleFonts.poppins(
    fontSize: 10.5,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static TextStyle price = GoogleFonts.poppins(
    fontSize: 19,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
}
