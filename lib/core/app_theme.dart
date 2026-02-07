import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF6366F1); // Indigo
  static const secondaryColor = Color(0xFFEC4899); // Pink
  static const scaffoldBackground = CupertinoColors.systemGroupedBackground;

  static const CupertinoThemeData lightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldBackground,
    barBackgroundColor: CupertinoColors.systemBackground,
    textTheme: CupertinoTextThemeData(
      primaryColor: primaryColor,
      textStyle: TextStyle(
        inherit: false,
        fontFamily: 'System', 
        color: CupertinoColors.label,
        fontSize: 17,
      ),
      navTitleTextStyle: TextStyle(
        inherit: false,
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: CupertinoColors.label,
      ),
      navLargeTitleTextStyle: TextStyle(
        inherit: false,
        fontWeight: FontWeight.bold, // iOS Large Title is usually very bold
        fontSize: 34,
        color: CupertinoColors.label,
        letterSpacing: -0.5,
      ),
    ),
  );

  static const CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: CupertinoColors.systemBackground, // Dark mode usually pure black or very dark grey
    barBackgroundColor: CupertinoColors.systemBackground,
    textTheme: CupertinoTextThemeData(
      primaryColor: primaryColor,
      textStyle: TextStyle(
        inherit: false,
        fontFamily: 'System',
        color: CupertinoColors.white,
        fontSize: 17,
      ),
      navTitleTextStyle: TextStyle(
        inherit: false,
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: CupertinoColors.white,
      ),
      navLargeTitleTextStyle: TextStyle(
        inherit: false,
        fontWeight: FontWeight.bold,
        fontSize: 34,
        color: CupertinoColors.white,
        letterSpacing: -0.5,
      ),
    ),
  );
}
