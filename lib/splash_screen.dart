import 'dart:async';

import 'package:flutter/material.dart';

import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Add any initialization code here
    Timer(Duration(seconds: 3), () => Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => MyHomePage())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // set the background color
      body: Center(
        child: Image.asset(
          'assets/logo.png', // set the path to the image asset
          width: 200.0, // set the width of the image
          height: 200.0, // set the height of the image
        ),
      ),
    );
  }
}
