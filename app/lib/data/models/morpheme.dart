import 'package:app/data/models/character.dart';
import 'package:app/data/models/data_model.dart';
import 'package:app/data/models/word.dart';

class Morpheme extends DataModel {
  List<Morpheme>? synonyms;
  List<Morpheme>? doublets;
  List<Character>? definitiveCharacters;
  List<Character>? tentativeCharacters;
  List<Word>? words;

  Morpheme({
    super.id = 0,
    required super.form,
    this.synonyms,
    this.doublets,
    this.definitiveCharacters,
    this.tentativeCharacters,
    this.words,
    super.notes = "",
  });
  
  Map<String, Object?> toMap() => {
    "id": (id == 0)? null : id,
    "form": form,
    "notes": notes,
  };
}