import 'package:app/data/models/data_model.dart';
import 'package:app/data/models/morpheme.dart';

class Character extends DataModel {
  List<Morpheme>? definitiveMeanings;
  List<Morpheme>? tentativeMeanings;
  List<String>? extantPronunciations;
  List<String>? definitivePronunciations;
  List<String>? tentativePronunciations;
  List<Character>? components;
  List<Character>? products;

  Character({
    super.id = 0,
    required super.form,
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