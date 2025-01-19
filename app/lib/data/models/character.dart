class Character {
  int id;
  String glyph;
  String notes;
  List<int>? definitiveMeaningIds;
  List<int>? tentativeMeaningIds;
  List<String>? extantPronunciations;
  List<String>? definitivePronunciations;
  List<String>? tentativePronunciations;
  List<int>? componentIds;
  List<int>? derivedIds;

  Character({required this.id, required this.glyph, this.notes = "",});
}