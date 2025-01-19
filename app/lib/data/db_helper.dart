import 'package:app/data/models/character.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  late Database db;

  DbHelper._internal();
  static final DbHelper helper = DbHelper._internal();
  factory DbHelper() => helper;

  Future<Database> openDb() async {
    db = await openDatabase(
      join(await getDatabasesPath(), 'han_log.db'),
      onCreate: (database, version) {        
        // words
        database.execute(
          "CREATE TABLE words(id INTEGER PRIMARY KEY, form TEXT, notes TEXT)"
        );
        database.execute(
          "CREATE TABLE wordSynonyms(id INTEGER PRIMARY KEY, wordIdA INTEGER, wordIdB INTEGER, "
          "FOREIGN KEY(wordIdA) REFERENCES words(id), "
          "FOREIGN KEY(wordIdB) REFERENCES words(id))"
        );
        database.execute(
          "CREATE TABLE wordCalques(id INTEGER PRIMARY KEY, wordIdA INTEGER, wordIdB INTEGER, "
          "FOREIGN KEY(wordIdA) REFERENCES words(id), "
          "FOREIGN KEY(wordIdB) REFERENCES words(id))"
        );
        // morphemes
        database.execute(
          "CREATE TABLE morphemes(id INTEGER PRIMARY KEY, form TEXT, notes TEXT)"
        );
        database.execute(
          "CREATE TABLE morphemeSynonyms(id INTEGER PRIMARY KEY, morphemeIdA INTEGER, morphemeIdB INTEGER, "
          "FOREIGN KEY(morphemeIdA) REFERENCES morphemes(id), "
          "FOREIGN KEY(morphemeIdB) REFERENCES morphemes(id))"
        );
        database.execute(
          "CREATE TABLE morphemeDoublets(id INTEGER PRIMARY KEY, morphemeIdA INTEGER, morphemeIdB INTEGER, "
          "FOREIGN KEY(morphemeIdA) REFERENCES morphemes(id), "
          "FOREIGN KEY(morphemeIdB) REFERENCES morphemes(id))"
        );
        // characters
        database.execute(
          "CREATE TABLE characters(id INTEGER PRIMARY KEY, glyph TEXT, notes TEXT)"
        );
        database.execute(
          "CREATE TABLE characterMeanings(id INTEGER PRIMARY KEY, isDefinitive INTEGER, "
          "characterId INTEGER, morphemeId INTEGER, "
          "FOREIGN KEY(characterId) REFERENCES characters(id), "
          "FOREIGN KEY(morphemeId) REFERENCES morphemes(id))"
        );
        database.execute(
          "CREATE TABLE characterPronunciations(id INTEGER PRIMARY KEY, isDefinitive INTEGER, "
          "pronunciation TEXT, characterId INTEGER, "
          "FOREIGN KEY(characterId) REFERENCES characters(id))"
        );
        database.execute(
          "CREATE TABLE characterCompositions(id INTEGER PRIMARY KEY, "
          "componentId INTEGER, composedId INTEGER, "
          "FOREIGN KEY(componentId) REFERENCES characters(id), "
          "FOREIGN KEY(composedId) REFERENCES characters(id))"
        );
      },
      version: 1
    );
    return db;
  }

  Future<List<Character>> getCharacters({
    Map<String, dynamic>? filter,
    int? limit,
    int? offset
  }) async {
    List<Map<String, dynamic>> chars = await db.query(
      "characters",
      where: filter == null ? null : [for (String key in filter.keys) "$key = ?"].join(),
      whereArgs: filter?.values.toList(),
      columns: ["id", "glyph", "notes"],
      limit: limit,
      offset: offset,
    );
    return List.generate(chars.length, (int i) => Character(
      id: chars[i]["id"],
      glyph: chars[i]["glyph"],
      notes: chars[i]["notes"],
    ), growable: false);
  }

  Future<void> getCharacterDetails(Character char) async {
    db.query(
      "characterMeanings", 
      where: "characterId = ? AND isDefinitive = 0",
      whereArgs: [char.id],
      columns: ["morphemeId"],
    ).then((value) {char.tentativeMeaningIds = 
      value.map((item) => item["morphemeId"] as int).toList()
    ;},);
    db.query(
      "characterMeanings", 
      where: "characterId = ? AND isDefinitive = 1",
      whereArgs: [char.id],
      columns: ["morphemeId"],
    ).then((value) {char.definitiveMeaningIds = 
      value.map((item) => item["morphemeId"] as int).toList()
    ;},);
    db.query(
      "characterPronunciations", 
      where: "characterId = ? AND isDefinitive = NULL",
      whereArgs: [char.id],
      columns: ["pronunciation"],
    ).then((value) {char.extantPronunciations = 
      value.map((item) => item["pronunciation"] as String).toList()
    ;},);
    db.query(
      "characterPronunciations", 
      where: "characterId = ? AND isDefinitive = 0",
      whereArgs: [char.id],
      columns: ["pronunciation"],
    ).then((value) {char.tentativePronunciations = 
      value.map((item) => item["pronunciation"] as String).toList()
    ;},);
    db.query(
      "characterPronunciations", 
      where: "characterId = ? AND isDefinitive = 1",
      whereArgs: [char.id],
      columns: ["pronunciation"],
    ).then((value) {char.definitivePronunciations =
      value.map((item) => item["pronunciation"] as String).toList()
    ;});
    db.query(
      "characterCompositions", 
      where: "composedId = ?",
      whereArgs: [char.id],
      columns: ["componentId"],
    ).then((value) {char.componentIds = 
      value.map((item) => item["componentId"] as int).toList()
    ;},);
    db.query(
      "characterCompositions", 
      where: "componentId = ?",
      whereArgs: [char.id],
      columns: ["composedId"],
    ).then((value) {char.derivedIds = 
      value.map((item) => item["composedId"] as int).toList()
    ;});
  }
}