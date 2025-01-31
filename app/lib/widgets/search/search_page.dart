import 'package:app/data/models/data_model.dart';
import 'package:app/widgets/item_page.dart';
import 'package:app/widgets/items_list.dart';
import 'package:app/widgets/search/search_dialog.dart';
import 'package:app/widgets/search/search_filter.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  /// if this page is being used to search for an item to return,
  /// set [lockedCategory] to a value other than [ItemType.none]
  /// representing the type of item to be returned
  final ItemType lockedCategory;
  const SearchPage({super.key, 
    this.lockedCategory = ItemType.none,
  });
  
  @override
  State<SearchPage> createState() => _SeachPageState();
}

class _SeachPageState extends State<SearchPage> {
  late SearchFilter searchFilter;
  _SeachPageState();

  @override
  void initState() {
    super.initState();
    searchFilter = SearchFilter(category: widget.lockedCategory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // search results
      body: ItemsList(
        title: "results",
        itemType: searchFilter.category,
        returnMode: widget.lockedCategory != ItemType.none,
      ),
      // appbar
      bottomNavigationBar: BottomAppBar(child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // refresh
          IconButton(onPressed: () {setState(() {});}, icon: Icon(Icons.refresh)),
          // apply search filters
          IconButton(icon: Icon(Icons.filter_alt), onPressed: () {
            showDialog(context: context, builder: (context) => 
              SearchDialog(categoryLock: widget.lockedCategory,)
            ,).then(
              (value) {setState(() {searchFilter = value;});}
            );
          },),
          // add entry
          if (searchFilter.category != ItemType.none) IconButton(icon: Icon(Icons.add), onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => 
              ItemPage(searchFilter.category)
            ));
          },),
        ],
      ),),
    );
  }
}