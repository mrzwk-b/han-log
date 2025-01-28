import 'package:app/data/affiliation.dart';
import 'package:app/data/db_helper.dart';
import 'package:app/data/models/data_model.dart';
import 'package:app/data/models/morpheme.dart';
import 'package:app/widgets/items_list.dart';
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
    // avoid infinite loop (build -> initializeMorpheme -> setState -> build)
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
    else if (morpheme!.synonyms == null) {
      await dbHelper.getMorphemeDetails(morpheme!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    initializeMorpheme();
    return Column(children: [
      Row(children: [
        Text("form"),
        (editMode) ? 
          TextField(onChanged: (value) {
            morpheme?.form = value;
          },):
          Text(morpheme?.form ?? "")
        ,
      ]),
      // guarantee that morpheme has been entered into db before filling in other fields
      if ((morpheme?.id ?? 0) != 0) for (Widget item in [
        Row(children: [
          Text("notes"),
          (editMode) ? 
            TextField():
            Text(morpheme?.notes ?? "")
          ,
        ]),
        ItemsList(
          title: "synonyms",
          affiliation: Affiliation(
            itemType: ItemType.morpheme
          ),
          items: morpheme?.synonyms ?? [],
        ),
        ItemsList(
          title: "doublets",
          affiliation: Affiliation(
            itemType: ItemType.morpheme
          ),
          items: morpheme?.doublets ?? [],
        ),
        ItemsList(
          title: "characters (definitive)",
          affiliation: Affiliation(
            itemType: ItemType.character
          ),
          items: morpheme?.definitiveCharacters ?? [],
        ),
        ItemsList(
          title: "characters (tentative)",
          affiliation: Affiliation(
            itemType: ItemType.character
          ),
          items: morpheme?.tentativeCharacters ?? [],
        ),
        ItemsList(
          title: "derived words",
          affiliation: Affiliation(
            itemType: ItemType.word
          ),
          items: morpheme?.words ?? [],
        ),
      ]) item
    ]);
  }
}