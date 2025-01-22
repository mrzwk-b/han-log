import 'package:app/widgets/listviews/characters_list.dart';
import 'package:app/widgets/listviews/morphemes_list.dart';
import 'package:flutter/material.dart';

enum SearchCategory {morpheme, word, character, none}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  
  @override
  State<SearchPage> createState() => _SeachPageState();
}

class _SeachPageState extends State<SearchPage> {
  SearchCategory category;
  Map<String, dynamic> filter;

  _SeachPageState(): 
    category = SearchCategory.none, 
    filter = {}
  ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (category) {
        SearchCategory.character => CharactersList(), // TODO
        SearchCategory.morpheme => MorphemesList(filter),
        SearchCategory.word => throw UnimplementedError(), // TODO
        SearchCategory.none => Container(), // might need to find a better empty element TODO
      },
      bottomNavigationBar: BottomAppBar(child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // category
          IconButton(icon: Icon(Icons.filter_alt), onPressed: () {
            showDialog(context: context, builder: (context) => AlertDialog(
              // TODO
            ),);
          },),
          IconButton(icon: Icon(Icons.add), onPressed: () {
            // TODO
          },),
        ],
      ),),
    );
  }
}