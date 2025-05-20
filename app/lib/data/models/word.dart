import 'package:app/data/models/data_model.dart';

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
}