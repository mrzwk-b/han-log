import 'package:flutter/material.dart';

enum SearchCategory {morpheme, word, character, none}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  
  @override
  State<SearchPage> createState() => _SeachPageState();
}

class _SeachPageState extends State<SearchPage> {
  SearchCategory category;
  _SeachPageState(): category = SearchCategory.none;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (category) {
        SearchCategory.character => throw UnimplementedError(),
        SearchCategory.morpheme => throw UnimplementedError(),
        SearchCategory.word => throw UnimplementedError(),
        SearchCategory.none => Container(), // might need to find a better empty element TODO
      },
      bottomNavigationBar: BottomAppBar(child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // category
          PopupMenuButton(
            icon: Icon(Icons.category),
            itemBuilder: (context) => [
              // morphemes
              PopupMenuItem(child: TextButton(
                onPressed: () {setState(() {
                  category = SearchCategory.morpheme;
                });},
                child: Text("morphemes")
              ),),
              // words
              PopupMenuItem(child: TextButton(
                onPressed: () {setState(() {
                  category = SearchCategory.word;
                });},
                child: Text("words")
              ),),
              // characters
              PopupMenuItem(child: TextButton(
                onPressed: () {setState(() {
                  category = SearchCategory.character;
                });},
                child: Text("characters")
              ),),
            ],
          ),
        ],
      ),),
    );
  }
}