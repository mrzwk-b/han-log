import 'package:app/data/db_helper.dart';
import 'package:app/data/models/character.dart';
import 'package:app/data/models/data_model.dart';
import 'package:app/data/models/morpheme.dart';
import 'package:app/data/models/word.dart';
import 'package:app/widgets/items_list.dart';
import 'package:flutter/material.dart';

/// displays the details of an item, potentially editable,
/// 
/// if no item is provided, the page will be used to create a new entry
class ItemPage extends StatefulWidget {
  final ItemType itemType;
  final int itemId;
  const ItemPage(this.itemType, {this.itemId = 0, super.key});
  
  @override
  State<StatefulWidget> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  DbHelper dbHelper = DbHelper();
  DataModel? item;
  late bool editMode;
  late Future<List<DataModel>> Function(Map<String, dynamic>?) itemGetter;
  late Future<void> Function(DataModel) detailsGetter;
  _ItemPageState();

  @override
  void initState() {
    super.initState();
    editMode = widget.itemId == 0;
    switch (widget.itemType) {
      case ItemType.morpheme:
        itemGetter = (filter) => dbHelper.getMorphemes(filter: filter);
        detailsGetter = (item) => dbHelper.getMorphemeDetails(item as Morpheme);
      case ItemType.word:
        itemGetter = (filter) => dbHelper.getWords(filter: filter);
        detailsGetter = (item) => dbHelper.getWordDetails(item as Word);
      case ItemType.character:
        itemGetter = (filter) => dbHelper.getCharacters(filter: filter);
        detailsGetter = (item) => dbHelper.getCharacterDetails(item as Character);
      case ItemType.none:
        throw UnsupportedError('cannot get items of type "none"');
    }
  }

  Future<void> initializeItem() async {
    // avoid infinite loop (build -> initializeMorpheme -> setState -> build)
    if (item == null) {
      if (widget.itemId == 0) {
        item = Morpheme(form: "");
      }
      else {
        item = (await itemGetter({"id": widget.itemId})).single;
        await detailsGetter(item!);
      }
      setState(() {});
    }
    else if (!item!.hasDetails) {
      await detailsGetter(item!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    initializeItem();
    return Column(children: [
      Row(children: [
        Text("form"),
        TextFormField(
          initialValue: item?.form,
          onChanged: (value) {
            item?.form = value;
          },
          readOnly: editMode,
        ),
      ]),
      // guarantee that item has been entered into db before filling in other fields
      if ((item?.id ?? 0) != 0) for (Widget item in [
        Row(children: [
          Text("notes"),
          TextFormField(
            initialValue: item?.notes,
            onChanged: (value) {
              item?.notes = value;
            },
            readOnly: editMode
          ),
        ]),
        for (ItemsList itemsList in switch (widget.itemType) {
          ItemType.morpheme => () {
            Morpheme morpheme = item as Morpheme;
            return [
              ItemsList(title: "synonyms",
                itemType: ItemType.morpheme,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertMorphemeSynonym(morpheme.id, otherId)
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteMorphemeSynonym(morpheme.id, otherId)
                ,
                items: morpheme.synonyms ?? [],
              ),
              ItemsList(title: "doublets",
                itemType: ItemType.morpheme,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertMorphemeDoublet(morpheme.id, otherId)
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteMorphemeDoublet(morpheme.id, otherId)
                ,
                items: morpheme.doublets ?? [],
              ),
              ItemsList(title: "characters (definitive)",
                itemType: ItemType.character,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertCharacterMeaning(
                    characterId: otherId,
                    morphemeId: morpheme.id,
                    isDefinitive: true
                  )
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteCharacterMeaning(
                    characterId: otherId,
                    morphemeId: morpheme.id,
                  )
                ,
                items: morpheme.definitiveCharacters ?? [],
              ),
              ItemsList(title: "characters (tentative)",
                itemType: ItemType.character,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertCharacterMeaning(
                    characterId: otherId,
                    morphemeId: morpheme.id,
                    isDefinitive: false
                  )
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteCharacterMeaning(
                    characterId: otherId,
                    morphemeId: morpheme.id,
                  )
                ,
                items: morpheme.tentativeCharacters ?? [],
              ),
              ItemsList(title: "derived words",
                itemType: ItemType.word,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertWordComposition(morphemeId: morpheme.id, wordId: otherId,)
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteWordComposition(morphemeId: morpheme.id, wordId: otherId,)
                ,
                items: morpheme.words ?? [],
              ),
            ];
          }(),
          ItemType.word => () {
            Word word = item as Word;
            return [
              ItemsList(title: "synonyms",
                itemType: ItemType.word,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertWordSynonym(word.id, otherId)
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteWordSynonym(word.id, otherId)
                ,
                items: word.synonyms ?? [],
              ),
              ItemsList(title: "calques",
                itemType: ItemType.word,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertWordCalque(word.id, otherId)
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteWordCalque(word.id, otherId)
                ,
                items: word.calques ?? [],
              ),
              ItemsList(title: "components",
                itemType: ItemType.word,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertWordComposition(wordId: word.id, morphemeId: otherId)
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteWordComposition(wordId: word.id, morphemeId: otherId)
                ,
                items: word.components ?? [],
              ),
            ];
          }(),
          ItemType.character => () {
            Character character = item as Character;
            return [
              ItemsList(title: "synonyms",
                itemType: ItemType.character,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertCharacterSynonym(character.id, otherId)
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteCharacterSynonym(character.id, otherId)
                ,
                items: character.synonyms ?? [],
              ),
              ItemsList(title: "meanings (definitive)",
                itemType: ItemType.character,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertCharacterMeaning(
                    characterId: character.id,
                    morphemeId: otherId,
                    isDefinitive: true,
                  )
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteCharacterMeaning(
                    characterId: character.id,
                    morphemeId: otherId,
                  )
                ,
                items: character.definitiveMeanings ?? [],
              ),
              ItemsList(title: "meanings (tentative)",
                itemType: ItemType.character,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertCharacterMeaning(
                    characterId: character.id,
                    morphemeId: otherId,
                    isDefinitive: false,
                  )
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteCharacterMeaning(
                    characterId: character.id,
                    morphemeId: otherId,
                  )
                ,
                items: character.tentativeMeanings ?? [],
              ),
              ItemsList(title: "pronunciations (extant)",
                itemType: ItemType.character,
                insert: !editMode ? null :
                  (other) => dbHelper.insertCharacterPronunciation(
                    characterId: character.id,
                    pronunciation: other,
                    isDefinitive: null,
                  )
                ,
                delete: !editMode ? null :
                  (other) => dbHelper.deleteCharacterPronunciation(
                    characterId: character.id,
                    pronunciation: other,
                  )
                ,
                items: character.extantPronunciations ?? [],
              ),
              ItemsList(title: "pronunciations (definitive)",
                itemType: ItemType.character,
                insert: !editMode ? null :
                  (other) => dbHelper.insertCharacterPronunciation(
                    characterId: character.id,
                    pronunciation: other,
                    isDefinitive: true,
                  )
                ,
                delete: !editMode ? null :
                  (other) => dbHelper.deleteCharacterPronunciation(
                    characterId: character.id,
                    pronunciation: other,
                  )
                ,
                items: character.definitivePronunciations ?? [],
              ),
              ItemsList(title: "pronunciations (tentative)",
                itemType: ItemType.character,
                insert: !editMode ? null :
                  (other) => dbHelper.insertCharacterPronunciation(
                    characterId: character.id,
                    pronunciation: other,
                    isDefinitive: false,
                  )
                ,
                delete: !editMode ? null :
                  (other) => dbHelper.deleteCharacterPronunciation(
                    characterId: character.id,
                    pronunciation: other,
                  )
                ,
                items: character.tentativePronunciations ?? [],
              ),
              ItemsList(title: "components",
                itemType: ItemType.character,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertCharacterComposition(
                    composedId: character.id,
                    componentId: otherId
                  )
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteCharacterComposition(
                    composedId: character.id,
                    componentId: otherId
                  )
                ,
                items: character.components ?? [],
              ),
              ItemsList(title: "derived characters",
                itemType: ItemType.character,
                insert: !editMode ? null :
                  (otherId) => dbHelper.insertCharacterComposition(
                    componentId: character.id,
                    composedId: otherId
                  )
                ,
                delete: !editMode ? null :
                  (otherId) => dbHelper.deleteCharacterComposition(
                    componentId: character.id,
                    composedId: otherId
                  )
                ,
                items: character.products ?? [],
              ),
            ];
          }(),
          ItemType.none => [],
        }) itemsList,
              ]) item
    ]);
  }
}