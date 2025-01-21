class Character {
  int? id;
  String glyph;
  String notes;
  List<int>? definitiveMeaningIds;
  List<int>? tentativeMeaningIds;
  List<String>? extantPronunciations;
  List<String>? definitivePronunciations;
  List<String>? tentativePronunciations;
  List<int>? componentIds;
  List<int>? derivedIds;

  Character({
    this.id,
    required this.glyph,
    this.definitiveMeaningIds,
    this.tentativeMeaningIds,
    this.extantPronunciations,
    this.definitivePronunciations,
    this.tentativePronunciations,
    this.componentIds,
    this.derivedIds,
    this.notes = "",  
  });

  Map<String, Object?> toMap() => {
    if (id != null) "id": (id == 0)? null : id,
    "glyph": glyph,
    "notes": notes,
  };
}