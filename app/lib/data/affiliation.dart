import 'package:app/data/models/data_model.dart';

class Affiliation {
  Future<void> Function(int)? insert;
  Future<void> Function(int)? delete;
  ItemType itemType;
  Affiliation({this.insert, this.delete, required this.itemType});
}