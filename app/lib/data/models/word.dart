import 'package:app/data/models/data_model.dart';
import 'package:flutter/foundation.dart';

class Word extends DataModel {
  List<int>? components;
  List<int>? synonyms;
  List<int>? calques;

  Word({
    super.id = 0,
    required super.form, 
    this.components,
    this.synonyms,
    this.calques,
    super.notes = "",
  });
  
  Map<String, Object?> toMap() => {
    "id": (id == 0)? null : id,
    "form": form,
    "notes": notes,
  };

  @override
  bool operator ==(Object other) =>
    super == other &&
    other is Word &&
    (!hasDetails || !other.hasDetails || (
      listEquals(components, other.components) &&
      listEquals(synonyms, other.synonyms) &&
      listEquals(calques, other.calques)
    ))
  ;

  @override
  int get hashCode =>
    super.hashCode +
    (components?.reduce((a, b) => a + b) ?? 0) +
    (synonyms?.reduce((a, b) => a + b) ?? 0) +
    (calques?.reduce((a, b) => a + b) ?? 0)
  ;
}