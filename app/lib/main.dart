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
      home: const HomePage(title: 'Home'),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView.builder(itemBuilder: (context, index) {
          // TODO search for unresolved groups
        })
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.inversePrimary,
        child: Text(title),
        
      ),
    );
  }
}
