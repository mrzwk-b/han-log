import 'package:app/data/affiliation.dart';
import 'package:app/data/models/data_model.dart';
import 'package:app/widgets/itemviews/morpheme_page.dart';
import 'package:app/widgets/search/search_page.dart';
import 'package:flutter/material.dart';

class ItemsList extends StatefulWidget {
  final String title;
  /// if this DataModelsList is being used to display ts associated with another item,
  /// use an Affiliation to pass functions to insert and delete associations in the database
  final Affiliation? affiliation;
  /// the initial list of items displayed by this widget
  final List<DataModel> items;
  /// set if this widget is being used to select from a list of search results
  final bool returnMode;
  const ItemsList({
    required this.title,
    required this.affiliation,
    this.items = const [],
    this.returnMode = false,
    super.key
  }): 
    assert(
      !returnMode || affiliation == null, 
      "return mode prohibits modification of list"
    )
  ;
  
  @override
  State<StatefulWidget> createState() => _ItemsListState();
}

class _ItemsListState extends State<ItemsList> {
  late List<DataModel> items;
  bool removeMode = false;
  _ItemsListState() {
    items = widget.items;
  }

  Future<void> addItem() async {
    DataModel item = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SearchPage(
        // returnMode: true // DataModelODO make SearchPage responsive to this parameter
      ),)
    ) as DataModel;
    items.add(item);
    widget.affiliation!.insert(item.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Text(widget.title),
        // buttons for adding and removing items
        if (widget.affiliation != null) for (Widget item in [
          IconButton(
            onPressed: () {addItem();},
            icon: Icon(Icons.add)
          ),
          IconButton(
            onPressed: () {removeMode = !removeMode;},
            icon: (removeMode) ? Icon(Icons.done) : Icon(Icons.remove)
          ),
        ]) item
      ],),
      ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(items[index].form),
          subtitle: Text(items[index].notes),
          onTap: 
            (removeMode) ? () {
              widget.affiliation!.delete(items[index].id);
            }:
            (widget.returnMode) ? () {
              Navigator.of(context).pop(items[index]);
            }:
            () { // link mode
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => 
                MorphemePage(morphemeId: items[index].id) // TODO switch based on affiliation.itemType
              ));
            }
          ,
        ),
      )
    ]);
  }
}