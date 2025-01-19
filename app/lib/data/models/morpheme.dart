class Morpheme {
  int id;
  String form;
  String notes;
  List<int>? synonymIds;
  List<int>? doubletIds;
  int? definitiveCharacterId;
  List<int>? tentativeCharacterIds;

  Morpheme({
    required this.id,
    required this.form,
    this.synonymIds,
    this.doubletIds,
    this.definitiveCharacterId,
    this.tentativeCharacterIds,
    this.notes = "",
  });
}