import 'dart:io';
import 'package:app/data/data_entry.dart';
import 'package:app/pages/search.dart';

// none of this code is gonna end up in the finished app
// i just want some example data before i start integrating database stuff

enum DataPhase {id, glyph, notes}

List<DataEntry> getResults(SearchCategory category) {
  return category == SearchCategory.none ? [] : File(
    [
      Directory.current.path,
      "lib",
      "data",
      "temp_db",
      "${category.name}.csv"
    ].join(Platform.pathSeparator)
  ).readAsLinesSync().sublist(1).map((line) {
    List<String> fields = line.split(',');
    return switch (category) {
      SearchCategory.character => Character(fields[1], fields[2]),
      SearchCategory.morpheme => Morpheme(fields[1], fields[2]),
      SearchCategory.word => Word(fields[1], fields[2]),
      SearchCategory.none => throw UnsupportedError(
        "SearchCategory.none has no associated DataEntry subtype"
      ),
    };
  }).toList();
}