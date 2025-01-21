class Word {
  int? id;
  String form;
  String notes;
  List<int>? componentIds;
  List<int>? synonymIds;
  List<int>? calqueIds;

  Word({
    this.id,
    required this.form, 
    this.componentIds,
    this.synonymIds,
    this.calqueIds,
    this.notes = "",
  });
  
  Map<String, Object?> toMap() => {
    if (id != null) "id": (id == 0)? null : id,
    "form": form,
    "notes": notes,
  };
}