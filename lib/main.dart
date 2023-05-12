import 'package:flutter/material.dart';
import 'package:mozzwear/splash_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

void main() {
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'MozzWear App',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
