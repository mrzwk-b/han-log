import 'package:app/data/models/data_model.dart';
import 'package:app/widgets/search/search_filter.dart';
import 'package:flutter/material.dart';

/// dialog for applying filters to a search
class SearchDialog extends StatefulWidget {
  final ItemType categoryLock;
  const SearchDialog({super.key, this.categoryLock = ItemType.none,});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  ItemType searchCategory = ItemType.none;
  Map<String, dynamic> filtersMap = {};

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text("Search Filters"),
      children: [
        if (widget.categoryLock == ItemType.none) Row(children: [
          TextButton(
            onPressed: () {setState(() {
              searchCategory = ItemType.morpheme;
            });},
            child: Text("morphemes"),
          ),
          TextButton(
            onPressed: () {setState(() {
              searchCategory = ItemType.word;              
            });},
            child: Text("words"),
          ),
          TextButton(
            onPressed: () {setState(() {
              searchCategory = ItemType.character;              
            });},
            child: Text("characters"),
          ),
        ],),
        for (Widget item in switch (searchCategory) {
          // TODO: Handle this case.
          ItemType.morpheme => throw UnimplementedError(),
          // TODO: Handle this case.
          ItemType.word => throw UnimplementedError(),
          // TODO: Handle this case.
          ItemType.character => throw UnimplementedError(),
          ItemType.none => [],
        }) item,
        TextButton(child: Text("done"),
          onPressed: () {
            Navigator.of(context).pop(
              SearchFilter(category: searchCategory, filtersMap: filtersMap)
            );
          },
        ),
      ],
    );
  }
}