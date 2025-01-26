import 'package:app/widgets/search/search_filter.dart';
import 'package:flutter/material.dart';

/// dialog for applying filters to a search
class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  SearchCategory searchCategory = SearchCategory.none;
  Map<String, dynamic> filtersMap = {};

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text("Search Filters"),
      children: [
        Row(children: [
          TextButton(
            onPressed: () {setState(() {
              searchCategory = SearchCategory.morpheme;
            });},
            child: Text("morphemes"),
          ),
          TextButton(
            onPressed: () {setState(() {
              searchCategory = SearchCategory.word;              
            });},
            child: Text("words"),
          ),
          TextButton(
            onPressed: () {setState(() {
              searchCategory = SearchCategory.character;              
            });},
            child: Text("characters"),
          ),
        ],),
        if (searchCategory == SearchCategory.morpheme) for (Widget item in [
          // TODO morpheme search filters
        ]) item,
        if (searchCategory == SearchCategory.word) for (Widget item in [
          // TODO word filter fields
        ]) item,
        if (searchCategory == SearchCategory.character) for (Widget item in [
          // TODO character filter fields
        ]) item,
        TextButton(child: Text("done"),
          onPressed: () {
            Navigator.of(context).pop(
              SearchFilter(searchCategory: searchCategory, filtersMap: filtersMap)
            );
          },
        ),
      ],
    );
  }
}