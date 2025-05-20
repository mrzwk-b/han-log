import 'package:app/data/models/data_model.dart';

class Morpheme extends DataModel {
  List<int>? synonyms;
  List<int>? doublets;
  List<int>? definitiveCharacters;
  List<int>? tentativeCharacters;
  List<int>? words;

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
    "id": (id == 0) ? null : id,
    "form": form,
    "notes": notes,
  };
}