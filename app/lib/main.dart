import 'package:app/pages/groups.dart';
import 'package:app/pages/search.dart';
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
       home: Builder(builder: (context) => 
        Scaffold(
          body: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {Navigator.of(context).push(MaterialPageRoute(builder: (_) => 
                  SearchPage()
                ));},
                child: Text("search"),
              ),
              ElevatedButton(
                onPressed: () {Navigator.of(context).push(MaterialPageRoute(builder: (_) => 
                  GroupsPage()
                ));},
                child: Text("groups"),
              ),
          ],),)
        ),
      )
    );
  }
}

