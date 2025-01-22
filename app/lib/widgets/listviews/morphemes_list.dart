import 'package:app/data/db_helper.dart';
import 'package:app/data/models/morpheme.dart';
import 'package:flutter/material.dart';

class MorphemesList extends StatefulWidget {
  final Map<String, dynamic> filter;
  const MorphemesList(this.filter, {super.key});

  @override
  State<MorphemesList> createState() => _MorphemesListState();
}

class _MorphemesListState extends State<MorphemesList> {
  List<Morpheme>? items = [];

  Future<void> showData() async {
    if (items == null) {
      items = await DbHelper().getMorphemes(filter: widget.filter);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    showData();
    return Scaffold(
      body: ListView.builder(
        itemCount: (items ?? []).length,
        itemBuilder: (context, index) => ListTile(
          title: Text(items![index].form),
          subtitle: Text(items![index].notes),
          onTap: () {
            // Navigator.of(context).push(MorphemePage(items[index]));
          },
        ),
      ),
    );
  }
}