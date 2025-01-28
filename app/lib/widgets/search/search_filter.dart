import 'package:app/data/models/data_model.dart';

class SearchFilter {
  ItemType category;
  Map<String, dynamic> filtersMap;
  SearchFilter({
    this.category = ItemType.none,
    this.filtersMap = const {},
  });
}