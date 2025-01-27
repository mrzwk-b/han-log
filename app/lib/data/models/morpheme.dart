import 'package:app/data/models/data_model.dart';

class Morpheme extends DataModel {
  List<int>? synonymIds;
  List<int>? doubletIds;
  List<int>? definitiveCharacterIds;
  List<int>? tentativeCharacterIds;
  List<int>? wordIds;

  Morpheme({
    super.id = 0,
    required super.form,
    this.synonymIds,
    this.doubletIds,
    this.definitiveCharacterIds,
    this.tentativeCharacterIds,
    this.wordIds,
    super.notes = "",
  });
  
  Map<String, Object?> toMap() => {
    "id": (id == 0)? null : id,
    "form": form,
    "notes": notes,
  };
}