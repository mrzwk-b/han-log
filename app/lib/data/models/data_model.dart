enum ItemType {morpheme, word, character, none}

class DataModel {
  int id;
  String form;
  String notes;
  bool hasDetails = false;
  DataModel({this.id = 0, required this.form, this.notes = ""});

  @override
  bool operator ==(Object other) =>
    other is DataModel &&
    id == other.id &&
    form == other.form &&
    notes == other.notes
  ;
  
  @override
  int get hashCode => id + form.hashCode + notes.hashCode;
}