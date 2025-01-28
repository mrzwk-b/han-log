import 'package:app/data/models/data_model.dart';
import 'package:app/data/models/morpheme.dart';

class Word extends DataModel {
  List<Morpheme>? components;
  List<Word>? synonyms;
  List<Word>? calques;

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
}