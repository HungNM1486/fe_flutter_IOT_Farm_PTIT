import 'package:flutter/material.dart';

class AppFonts {
  static const String beVietNamPro = 'Be Vietnam Pro';

  static TextStyle be400(double fontSize, Color color) =>
      TextStyle(fontFamily: beVietNamPro, fontSize: fontSize, color: color, fontWeight: FontWeight.w400);

  static TextStyle be500(double fontSize, Color color) =>
      TextStyle(fontFamily: beVietNamPro, fontSize: fontSize, color: color, fontWeight: FontWeight.w500);

  static TextStyle be600(double fontSize, Color color) =>
      TextStyle(fontFamily: beVietNamPro, fontSize: fontSize, color: color, fontWeight: FontWeight.w600);

  static TextStyle be700(double fontSize, Color color) =>
      TextStyle(fontFamily: beVietNamPro, fontSize: fontSize, color: color, fontWeight: FontWeight.w700);
}
