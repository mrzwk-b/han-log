import 'package:app/widgets/items_list.dart';
import 'package:app/widgets/search/search_dialog.dart';
import 'package:app/widgets/search/search_filter.dart';
import 'package:flutter/material.dart';


class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  
  @override
  State<SearchPage> createState() => _SeachPageState();
}

class _SeachPageState extends State<SearchPage> {
  SearchFilter searchFilter;
  _SeachPageState(): searchFilter = SearchFilter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (searchFilter.searchCategory) {
        SearchCategory.character => CharactersList(), // TODO
        SearchCategory.morpheme => ItemsList(),
        SearchCategory.word => throw UnimplementedError(), // TODO
        SearchCategory.none => Container(), // might need to find a better empty element TODO
      },
      bottomNavigationBar: BottomAppBar(child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // apply search filters
          IconButton(icon: Icon(Icons.filter_alt), onPressed: () {
            showDialog(context: context, builder: (context) => SearchDialog()).then(
              (value) {setState(() {searchFilter = value;});}
            );
          },),
          // add entry
          IconButton(icon: Icon(Icons.add), onPressed: () {
            // TODO
          },),
        ],
      ),),
    );
  }
}