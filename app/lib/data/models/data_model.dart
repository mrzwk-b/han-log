enum ItemType {morpheme, word, character, none}

class DataModel {
  int id;
  String form;
  String notes;
  DataModel({this.id = 0, required this.form, this.notes = ""});
}