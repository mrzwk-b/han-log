import 'package:app/data/db_helper.dart';
import 'package:app/data/models/morpheme.dart';
import 'package:app/widgets/listviews/morphemes_list.dart';
import 'package:flutter/material.dart';

/// displays the details of a morpheme, potentially editable,
/// 
/// if no morpheme is provided, the page will be used to create a new entry
class MorphemePage extends StatefulWidget {
  final int morphemeId;
  const MorphemePage({this.morphemeId = 0, super.key});
  
  @override
  State<StatefulWidget> createState() => _MorphemePageState();
}

class _MorphemePageState extends State<MorphemePage> {
  DbHelper dbHelper = DbHelper();
  Morpheme? morpheme;
  late bool editMode;
  _MorphemePageState() {
    editMode = widget.morphemeId == 0;
  }

  Future<void> initializeMorpheme() async {
    if (morpheme == null) {
      if (widget.morphemeId == 0) {
        morpheme = Morpheme(form: "");
      }
      else {
        morpheme = (await dbHelper.getMorphemes(filter: {"id": widget.morphemeId})).single;
        await dbHelper.getMorphemeDetails(morpheme!);
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Text("form"),
        (editMode) ? 
          TextField():
          Text(morpheme?.form ?? "")
        ,
      ]),
      // should guarantee that morpheme has been entered into db before filling in other fields
      Row(children: [
        Text("notes"),
        (editMode) ? 
          TextField():
          Text(morpheme?.notes ?? "")
        ,
      ]),
      Row(children: [
        Text("synonyms"),
        if (editMode) IconButton(onPressed: () {}, icon: Icon(Icons.add))
      ]),
      MorphemesList(),
    ]);
  }
}