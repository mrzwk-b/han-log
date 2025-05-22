import 'package:app/data/models/data_model.dart';
import 'package:flutter/foundation.dart';

class Character extends DataModel {
  List<int>? synonyms;
  List<int>? definitiveMeanings;
  List<int>? tentativeMeanings;
  List<String>? extantPronunciations;
  List<String>? definitivePronunciations;
  List<String>? tentativePronunciations;
  List<int>? components;
  List<int>? products;

  Character({
    super.id = 0,
    required super.form,
    this.synonyms,
    this.definitiveMeanings,
    this.tentativeMeanings,
    this.extantPronunciations,
    this.definitivePronunciations,
    this.tentativePronunciations,
    this.components,
    this.products,
    super.notes = "",  
  });

  Map<String, Object?> toMap() => {
    "id": (id == 0)? null : id,
    "form": form,
    "notes": notes,
  };
  
  @override
  bool operator ==(Object other) =>
    super == other &&
    other is Character &&
    (!hasDetails || !other.hasDetails || (
      listEquals(synonyms, other.synonyms) &&
      listEquals(definitiveMeanings, other.definitiveMeanings) &&
      listEquals(tentativeMeanings, other.tentativeMeanings) &&
      listEquals(extantPronunciations, other.extantPronunciations) &&
      listEquals(definitivePronunciations, other.definitivePronunciations) &&
      listEquals(tentativePronunciations, other.tentativePronunciations) &&
      listEquals(components, other.components) &&
      listEquals(products, other.products)
    ))
  ;

  @override
  int get hashCode =>
    super.hashCode +
    (synonyms?.reduce((a, b) => a + b) ?? 0) +
    (definitiveMeanings?.reduce((a, b) => a + b) ?? 0) +
    (tentativeMeanings?.reduce((a, b) => a + b) ?? 0) +
    (extantPronunciations?.map((str) => str.hashCode).reduce((a, b) => a + b) ?? 0) +
    (definitivePronunciations?.map((str) => str.hashCode).reduce((a, b) => a + b) ?? 0) +
    (tentativePronunciations?.map((str) => str.hashCode).reduce((a, b) => a + b) ?? 0) +
    (components?.reduce((a, b) => a + b) ?? 0) +
    (products?.reduce((a, b) => a + b) ?? 0)
  ;
}