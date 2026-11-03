import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyle {
  static TextStyle titleTextStyle({Color color = Colors.black}) {
    return GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle subTitleTextStyle({Color color = Colors.black}) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle descriptionTextStyle({
    double fontSize = 14,
    Color color = Colors.black,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle buttonTextStyle({Color color = Colors.black}) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle textFieldTextStyle({Color color = Colors.black}) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle menuButtonsTextStyle({Color color = Colors.black}) {
    return GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle appBarTextStyle({Color color = Colors.black}) {
    return GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: color,
    );
  }
}
