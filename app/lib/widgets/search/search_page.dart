import 'package:app/data/affiliation.dart';
import 'package:app/data/models/data_model.dart';
import 'package:app/widgets/items_list.dart';
import 'package:app/widgets/search/search_dialog.dart';
import 'package:app/widgets/search/search_filter.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final ItemType categoryLock;
  final bool returnMode;
  const SearchPage({super.key,
    required this.returnMode,
    this.categoryLock = ItemType.none,
  });
  
  @override
  State<SearchPage> createState() => _SeachPageState();
}

class _SeachPageState extends State<SearchPage> {
  late SearchFilter searchFilter;
  _SeachPageState() {searchFilter = SearchFilter(category: widget.categoryLock);}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // search results
      body: ItemsList(
        title: "results",
        affiliation: Affiliation(itemType: searchFilter.category),
        returnMode: widget.returnMode,
      ),
      // appbar
      bottomNavigationBar: BottomAppBar(child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // apply search filters
          IconButton(icon: Icon(Icons.filter_alt), onPressed: () {
            showDialog(context: context, builder: (context) => 
              SearchDialog(categoryLock: widget.categoryLock,)
            ,).then(
              (value) {setState(() {searchFilter = value;});}
            );
          },),
          // add entry
          if (searchFilter.category != ItemType.none) IconButton(icon: Icon(Icons.add), onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => 
              Placeholder() // TODO figure out ItemPage
            ));
          },),
        ],
      ),),
    );
  }
}