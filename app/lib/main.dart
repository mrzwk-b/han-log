import 'package:app/navbar.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const HanLogApp());
}

class HanLogApp extends StatelessWidget {
  const HanLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Han Character Log',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.red,
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Placeholder(), // TODO navigate between various screens of the app
        bottomNavigationBar: Navbar(),
      ),
    );
  }
}

