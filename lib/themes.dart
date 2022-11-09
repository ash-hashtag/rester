import 'package:flutter/material.dart';

class MyThemes {
  static bool get darkMode => ThemeMode.dark == ThemeMode.system;

  static final lightTheme = ThemeData(
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
  );

  static final darkTheme = lightTheme;
}
