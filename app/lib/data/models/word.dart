import 'package:app/data/models/data_model.dart';

class Word extends DataModel {
  List<int>? componentIds;
  List<int>? synonymIds;
  List<int>? calqueIds;

  Word({
    super.id = 0,
    required super.form, 
    this.componentIds,
    this.synonymIds,
    this.calqueIds,
    super.notes = "",
  });
  
  Map<String, Object?> toMap() => {
    "id": (id == 0)? null : id,
    "form": form,
    "notes": notes,
  };
}