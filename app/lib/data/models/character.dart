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
    this.notes = "",
    this.definitiveMeaningIds,
    this.tentativeMeaningIds,
    this.extantPronunciations,
    this.definitivePronunciations,
    this.tentativePronunciations,
    this.componentIds,
    this.derivedIds,  
  });

  Map<String, Object?> toMap() => {
    "id": id == 0 ? null : id,
    "glyph": glyph,
    "notes": notes,
  };
}