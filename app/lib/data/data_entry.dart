class DataEntry {
  String form;
  String notes;
  DataEntry(this.form, this.notes);
}

class Character extends DataEntry {
  Character(super.form, super.notes);
}
class Word extends DataEntry {
  Word(super.form, super.notes);
}
class Morpheme extends DataEntry {
  Morpheme(super.form, super.notes);
}