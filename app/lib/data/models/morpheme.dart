class Morpheme {
  int id;
  String form;
  List<int> synonymIds;
  List<int> doubletIds;
  String notes;

  Morpheme(this.id, this.form, {
    this.synonymIds = const [],
    this.doubletIds = const [],
    this.notes = "",
  });
}