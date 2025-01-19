class Word {
  int id;
  String form;
  List<int> componentIds;
  List<int> synonymIds;
  List<int> calqueIds;
  String notes;

  Word(this.id, this.form, {
    this.componentIds = const [],
    this.synonymIds = const [],
    this.calqueIds = const [],
    this.notes = "",
  });
}