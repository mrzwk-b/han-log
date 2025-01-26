import 'package:app/data/models/morpheme.dart';
import 'package:app/widgets/itemviews/morpheme_page.dart';
import 'package:flutter/material.dart';

class MorphemesList extends StatelessWidget {
  // TODO make editable
  final List<Morpheme> items;
  const MorphemesList({this.items = const [], super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(items[index].form),
        subtitle: Text(items[index].notes),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => 
            MorphemePage(morphemeId: items[index].id!)
          ));
        },
      ),
    );
  }
}