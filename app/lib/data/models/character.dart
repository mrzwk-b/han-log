import 'package:app/data/models/data_model.dart';

class Character extends DataModel {
  List<int>? definitiveMeaningIds;
  List<int>? tentativeMeaningIds;
  List<String>? extantPronunciations;
  List<String>? definitivePronunciations;
  List<String>? tentativePronunciations;
  List<int>? componentIds;
  List<int>? derivedIds;

  Character({
    super.id = 0,
    required super.form,
    this.definitiveMeaningIds,
    this.tentativeMeaningIds,
    this.extantPronunciations,
    this.definitivePronunciations,
    this.tentativePronunciations,
    this.componentIds,
    this.derivedIds,
    super.notes = "",  
  });

  Map<String, Object?> toMap() => {
    "id": (id == 0)? null : id,
    "glyph": form,
    "notes": notes,
  };
}