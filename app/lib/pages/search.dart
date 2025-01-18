import 'package:app/data/data_entry.dart';
import 'package:app/data/read_db.dart';
import 'package:app/pages/item.dart';
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
    List<DataEntry> results = getResults(category);
    return Scaffold(
      body: ListView.builder(itemBuilder: (context, i) {
        return category == SearchCategory.none || i >= results.length ? 
          Placeholder() :
          Card(child: ListTile(
            onTap: () {Navigator.of(context).push(MaterialPageRoute((_) => ItemPage(results[i])))},
            leading: Text(results[i].form),
            title: Text(results[i].notes),  
          ),)
        ;
      }),
      bottomNavigationBar: BottomAppBar(child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {Navigator.of(context).pop();},
            icon: Icon(Icons.home_filled),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(child: TextButton(
                onPressed: () {setState(() {
                  category = SearchCategory.morpheme;
                });},
                child: Text("morphemes")
              ),),
              PopupMenuItem(child: TextButton(
                onPressed: () {setState(() {
                  category = SearchCategory.word;
                });},
                child: Text("words")
              ),),
              PopupMenuItem(child: TextButton(
                onPressed: () {setState(() {
                  category = SearchCategory.character;
                });},
                child: Text("characters")
              ),),
            ],
            icon: Icon(Icons.filter_alt_rounded)
          ),
        ],
      ),),
    );
  }
}