class Morpheme {
  int? id;
  String form;
  String notes;
  List<int>? synonymIds;
  List<int>? doubletIds;
  List<int>? definitiveCharacterIds;
  List<int>? tentativeCharacterIds;
  List<int>? wordIds;

  Morpheme({
    required this.id,
    required this.form,
    this.synonymIds,
    this.doubletIds,
    this.definitiveCharacterIds,
    this.tentativeCharacterIds,
    this.wordIds,
    this.notes = "",
  });
  
  Map<String, Object?> toMap() => {
    if (id != null) "id": (id == 0)? null : id,
    "form": form,
    "notes": notes,
  };
}