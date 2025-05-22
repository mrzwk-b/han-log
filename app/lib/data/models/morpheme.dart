import 'package:app/data/models/data_model.dart';
import 'package:flutter/foundation.dart';

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

  @override
  bool operator ==(Object other) =>
    super == other &&
    other is Morpheme &&
    (!hasDetails || !other.hasDetails || (
      listEquals(synonyms, other.synonyms) &&
      listEquals(doublets, other.doublets) &&
      listEquals(definitiveCharacters, other.definitiveCharacters) &&
      listEquals(tentativeCharacters, other.tentativeCharacters) &&
      listEquals(words, other.words)
    ))
  ;

  @override
  int get hashCode =>
    super.hashCode +
    (synonyms?.reduce((a, b) => a + b) ?? 0) +
    (doublets?.reduce((a, b) => a + b) ?? 0) +
    (definitiveCharacters?.reduce((a, b) => a + b) ?? 0) +
    (tentativeCharacters?.reduce((a, b) => a + b) ?? 0) +
    (words?.reduce((a, b) => a + b) ?? 0)
  ;
}