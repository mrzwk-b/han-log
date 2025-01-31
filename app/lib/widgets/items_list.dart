import 'package:app/data/models/data_model.dart';
import 'package:app/widgets/item_page.dart';
import 'package:app/widgets/search/search_page.dart';
import 'package:flutter/material.dart';

class ItemsList extends StatefulWidget {
  final String title;
  /// the type of items contained within this list (can be none, but only if [items] is empty)
  final ItemType itemType;
  /// if it should be possible to add items to this list, pass a database function with [insert]
  final Future<void> Function(dynamic)? insert;
  /// if it should be possible to remove items from this list, pass a database function with [delete]
  final Future<void> Function(dynamic)? delete;
  /// the initial list of items displayed by this widget
  final List<dynamic> items;
  /// set to [true] if this widget is being used to select from a list of search results
  final bool returnMode;
  const ItemsList({
    required this.title,
    required this.itemType,
    this.insert,
    this.delete,
    this.items = const [],
    this.returnMode = false,
    super.key
  });
  
  @override
  State<StatefulWidget> createState() => _ItemsListState();
}

class _ItemsListState extends State<ItemsList> {
  late List<dynamic> items;
  bool removeMode = false;
  _ItemsListState();

  @override
  void initState() {
    super.initState();
    items = widget.items;
  }

  Future<void> insertItem() async {
    DataModel? item = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SearchPage(lockedCategory: widget.itemType,),)
    ) as DataModel?;
    if (item != null) {
      items.add(item);
      await widget.insert!(item.id);
      setState(() {});
    }
  }

  Future<void> deleteItem(int index) async {
    DataModel item = items.removeAt(index);
    await widget.delete!(item.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Text(widget.title),
        // buttons for adding and removing items
        if (widget.insert != null) IconButton(
          onPressed: () {insertItem();},
          icon: Icon(Icons.add)
        ),
        if (widget.delete != null) IconButton(
          onPressed: () {removeMode = !removeMode;},
          icon: (removeMode) ? Icon(Icons.done) : Icon(Icons.remove)
        ),
      ],),
      Flexible(child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(items[index].form),
          subtitle: Text(items[index].notes),
          onTap: 
            (removeMode) ? () {
              deleteItem(index);
            }:
            (widget.returnMode) ? () {
              Navigator.of(context).pop(items[index]);
            }:
            () { // link mode
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => 
                ItemPage(widget.itemType, itemId: items[index].id)
              ));
            }
          ,
        ),
      ),)
    ]);
  }
}