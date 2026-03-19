import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  fontFamily: 'Montserrat',
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.light(
    primary: Colors.black,
    secondary: Colors.black,
    surface: Colors.white,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.black),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.black, width: 2),
    ),
    labelStyle: TextStyle(color: Colors.black),
  ),
  cardTheme: CardThemeData(
    color: Color(0xFFF5F5F5),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Color(0xFFE0E0E0)),
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.grey,
  ),
);
