import 'package:app/data/models/data_model.dart';

class Character extends DataModel {
  List<int>? synonyms;
  List<int>? definitiveMeanings;
  List<int>? tentativeMeanings;
  List<String>? extantPronunciations;
  List<String>? definitivePronunciations;
  List<String>? tentativePronunciations;
  List<int>? components;
  List<int>? products;

  Character({
    super.id = 0,
    required super.form,
    this.synonyms,
    this.definitiveMeanings,
    this.tentativeMeanings,
    this.extantPronunciations,
    this.definitivePronunciations,
    this.tentativePronunciations,
    this.components,
    this.products,
    super.notes = "",  
  });

  Map<String, Object?> toMap() => {
    "id": (id == 0)? null : id,
    "form": form,
    "notes": notes,
  };
}