enum ItemType {morpheme, word, character}

class Affiliation {
  Future<void> Function(int) insert;
  Future<void> Function(int) delete;
  ItemType itemType;
  Affiliation({required this.insert, required this.delete, required this.itemType});
}