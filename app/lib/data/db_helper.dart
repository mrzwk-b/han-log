import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/data/models/character.dart';
import 'package:app/data/models/morpheme.dart';
import 'package:app/data/models/word.dart';

class DbHelper {
  late Database _db;

  DbHelper._internal();
  static final DbHelper helper = DbHelper._internal();
  factory DbHelper() => helper;

  Future<Database> openDb() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    
    }
    _db = await databaseFactory.openDatabase(
      path.join(Directory.current.path, 'han_log.db'), // TODO probably need to make this more robust
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database database, int version) async {
          // morphemes
          await database.execute(
            "CREATE TABLE morphemes("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "form TEXT NOT NULL, "
            "notes TEXT NOT NULL)"
          );
          await database.execute(
            "CREATE TABLE morphemeSynonyms("
            "morphemeIdA INTEGER NOT NULL, "
            "morphemeIdB INTEGER NOT NULL, "
            "PRIMARY KEY(morphemeIdA, morphemeIdB), "
            "FOREIGN KEY(morphemeIdA) REFERENCES morphemes(id) ON DELETE CASCADE, "
            "FOREIGN KEY(morphemeIdB) REFERENCES morphemes(id) ON DELETE CASCADE"
            ") WITHOUT ROWID"
          );
          await database.execute(
            "CREATE TABLE morphemeDoublets("
            "morphemeIdA INTEGER NOT NULL, "
            "morphemeIdB INTEGER NOT NULL, "
            "PRIMARY KEY(morphemeIdA, morphemeIdB), "
            "FOREIGN KEY(morphemeIdA) REFERENCES morphemes(id) ON DELETE CASCADE, "
            "FOREIGN KEY(morphemeIdB) REFERENCES morphemes(id) ON DELETE CASCADE"
            ") WITHOUT ROWID"
          );
          // words
          await database.execute(
            "CREATE TABLE words("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "form TEXT NOT NULL, "
            "notes TEXT NOT NULL)"
          );
          await database.execute(
            "CREATE TABLE wordCompositions("
            "wordId INTEGER NOT NULL, "
            "morphemeId INTEGER NOT NULL, "
            "position INTEGER, "
            "PRIMARY KEY(wordId, position), "
            "FOREIGN KEY(wordId) REFERENCES words(id) ON DELETE CASCADE, "
            "FOREIGN KEY(morphemeId) REFERENCES morphemes(id) ON DELETE CASCADE"
            ") WITHOUT ROWID"
          );
          await database.execute(
            "CREATE TABLE wordSynonyms("
            "wordIdA INTEGER NOT NULL, "
            "wordIdB INTEGER NOT NULL, "
            "PRIMARY KEY(wordIdA, wordIdB), "
            "FOREIGN KEY(wordIdA) REFERENCES words(id) ON DELETE CASCADE, "
            "FOREIGN KEY(wordIdB) REFERENCES words(id) ON DELETE CASCADE"
            ") WITHOUT ROWID"
          );
          await database.execute(
            "CREATE TABLE wordCalques("
            "wordIdA INTEGER NOT NULL, "
            "wordIdB INTEGER NOT NULL, "
            "PRIMARY KEY(wordIdA, wordIdB), "
            "FOREIGN KEY(wordIdA) REFERENCES words(id) ON DELETE CASCADE, "
            "FOREIGN KEY(wordIdB) REFERENCES words(id) ON DELETE CASCADE"
            ") WITHOUT ROWID"
          );
          // characters
          await database.execute(
            "CREATE TABLE characters("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "form TEXT NOT NULL UNIQUE, "
            "notes TEXT NOT NULL)"
          );
          await database.execute(
            "CREATE TABLE characterMeanings("
            "isDefinitive INTEGER NOT NULL, "
            "characterId INTEGER NOT NULL, "
            "morphemeId INTEGER NOT NULL, "
            "PRIMARY KEY(characterId, morphemeId), "
            "FOREIGN KEY(characterId) REFERENCES characters(id) ON DELETE CASCADE, "
            "FOREIGN KEY(morphemeId) REFERENCES morphemes(id) ON DELETE CASCADE"
            ") WITHOUT ROWID"
          );
          await database.execute(
            "CREATE TABLE characterPronunciations("
            "isDefinitive INTEGER, "
            "pronunciation TEXT NOT NULL, "
            "characterId INTEGER NOT NULL, "
            "PRIMARY KEY(characterId, pronunciation), "
            "FOREIGN KEY(characterId) REFERENCES characters(id) ON DELETE CASCADE"
            ") WITHOUT ROWID"
          );
          await database.execute(
            "CREATE TABLE characterCompositions("
            "componentId INTEGER NOT NULL, "
            "composedId INTEGER NOT NULL, "
            "PRIMARY KEY(componentId, composedId), "
            "FOREIGN KEY(componentId) REFERENCES characters(id) ON DELETE CASCADE, "
            "FOREIGN KEY(composedId) REFERENCES characters(id) ON DELETE CASCADE"
            ") WITHOUT ROWID"
          );
          await database.execute(
            "CREATE TABLE characterSynonyms("
            "characterIdA INTEGER NOT NULL, "
            "characterIdB INTEGER NOT NULL, "
            "PRIMARY KEY(characterIdA, characterIdB), "
            "FOREIGN KEY(characterIdA) REFERENCES characters(id) ON DELETE CASCADE, "
            "FOREIGN KEY(characterIdB) REFERENCES characters(id) ON DELETE CASCADE"
            ") WITHOUT ROWID"
          );
        },
      ),
    );
    return _db;
  }

  // morphemes

  Future<List<Morpheme>> getMorphemes({
    Map<String, Object?>? filter,
    int? limit,
    int? offset
  }) async =>
    (await _db.query("morphemes",
      where: filter == null ? null : [for (String key in filter.keys) "$key = ?"].join(),
      whereArgs: filter?.values.toList(),
      columns: ["id", "form", "notes"],
      limit: limit,
      offset: offset,
    )).map((data) => Morpheme(
      id:  data["id"] as int,
      form: data["form"] as String,
      notes: data["notes"] as String,
    )).toList(growable: false)
  ;

  Future<void> getMorphemeDetails(Morpheme morpheme) async {
    for (Future assignment in [
      getMorphemeSynonymIds(morpheme.id).then((value) {morpheme.synonyms = value;},),
      getMorphemeDoubletIds(morpheme.id).then((value) {morpheme.doublets = value;},),
      getMorphemeTransliterationIds(morpheme.id, true).then((value) {morpheme.definitiveCharacters = value;},),
      getMorphemeTransliterationIds(morpheme.id, false).then((value) {morpheme.tentativeCharacters = value;},),
      getMorphemeProductIds(morpheme.id).then((value) {morpheme.words = value;},),
    ]) {await assignment;}
    morpheme.hasDetails = true;
  }

  Future<int> insertMorpheme(Morpheme morpheme) async {
    int id = await _db.insert("morphemes", morpheme.toMap());
    morpheme.id = id;
    if (id != 0) {
      for (Future insertion in [
        for (int synonymId in morpheme.synonyms ?? []) 
          insertMorphemeSynonym(id, synonymId)
        ,
        for (int doubletId in morpheme.doublets ?? [])
          insertMorphemeDoublet(id, doubletId)
        ,
        for (int characterId in morpheme.definitiveCharacters ?? [])
          insertCharacterMeaning(characterId: characterId, morphemeId: id, isDefinitive: true)
        ,
        for (int characterId in morpheme.tentativeCharacters ?? [])
          insertCharacterMeaning(characterId: characterId, morphemeId: id, isDefinitive: false)
        ,
        for (int wordId in morpheme.words ?? [])
          insertWordComposition(wordId: wordId, morphemeId: id)
        ,
      ]) {await insertion;}
    }
    return id;
  }
  
  Future<void> updateMorpheme(Morpheme morpheme) async {
    await _db.update("morphemes", morpheme.toMap(), where: "id = ?", whereArgs: [morpheme.id]);
  }
  
  Future<void> deleteMorpheme(int morphemeId) async {
    await _db.delete("morphemes", where: "id = ?", whereArgs: [morphemeId]);
  }
  
  Future<List<int>> getMorphemeSynonymIds(int morphemeId) async => [
    for (Map<String, Object?> synonym in await _db.query("morphemeSynonyms",
      where: "morphemeIdA = ?",
      whereArgs: [morphemeId],
      columns: ["morphemeIdB"]
    )) synonym["morphemeIdB"] as int
  ];
  
  Future<void> insertMorphemeSynonym(int morphemeIdA, int morphemeIdB) async {
    await _db.insert("morphemeSynonyms", {
      "morphemeIdA": morphemeIdA,
      "morphemeIdB": morphemeIdB,
    });
    await _db.insert("morphemeSynonyms", {
      "morphemeIdA": morphemeIdB,
      "morphemeIdB": morphemeIdA,
    });
  }

  Future<void> deleteMorphemeSynonym(int morphemeIdA, int morphemeIdB) async {
    await _db.delete("morphemeSynonyms",
      where: "morphemeIdA = ? AND morphemeIdB = ?",
      whereArgs: [morphemeIdA, morphemeIdB],
    );
    await _db.delete("morphemeSynonyms",
      where: "morphemeIdA = ? AND morphemeIdB = ?",
      whereArgs: [morphemeIdB, morphemeIdA],
    );
  }
  
  Future<List<int>> getMorphemeDoubletIds(int morphemeId) async => [
    for (Map<String, Object?> doublet in await _db.query("morphemeDoublets",
      where: "morphemeIdA = ?",
      whereArgs: [morphemeId],
      columns: ["morphemeIdB"]
    )) doublet["morphemeIdB"] as int
  ];
  
  Future<void> insertMorphemeDoublet(int morphemeIdA, int morphemeIdB) async {
    await _db.insert("morphemeDoublets", {
      "morphemeIdA": morphemeIdA,
      "morphemeIdB": morphemeIdB,
    });
    await _db.insert("morphemeDoublets", {
      "morphemeIdA": morphemeIdB,
      "morphemeIdB": morphemeIdA,
    });
  }

  Future<void> deleteMorphemeDoublet(int morphemeIdA, int morphemeIdB) async {
    await _db.delete("morphemeDoublets",
      where: "morphemeIdA = ? AND morphemeIdB = ?",
      whereArgs: [morphemeIdA, morphemeIdB],
    );
    await _db.delete("morphemeDoublets",
      where: "morphemeIdA = ? AND morphemeIdB = ?",
      whereArgs: [morphemeIdB, morphemeIdA],
    );
  }

  // words

  Future<List<Word>> getWords({
    Map<String, Object?>? filter,
    int? limit,
    int? offset
  }) async => (await _db.query("words",
      where: filter == null ? null : [for (String key in filter.keys) "$key = ?"].join(),
      whereArgs: filter?.values.toList(),
      columns: ["id", "form", "notes"],
      limit: limit,
      offset: offset,
    )).map((data) => Word(
      id: data["id"] as int,
      form: data["form"] as String,
      notes: data["notes"] as String,
    )).toList(growable: false)
  ;

  Future<void> getWordDetails(Word word) async {
    for (Future assignment in [
      getWordComponentIds(word.id).then((value) {word.components = value;},),
      getWordSynonymIds(word.id).then((value) {word.synonyms = value;},),
      getWordCalqueIds(word.id).then((value) {word.calques = value;},),
    ]) {await assignment;}
    word.hasDetails = true;
  }

  Future<int> insertWord(Word word) async {
    int id = await _db.insert("words", word.toMap());
    word.id = id;
    for (Future insertion in [
      for (int synonymId in word.synonyms ?? []) 
        insertWordSynonym(word.id, synonymId)
      ,
      for (int calqueId in word.calques ?? [])
        insertWordCalque(word.id, calqueId)
      ,
      for (int morphemeId in word.components ?? [])
        insertWordComposition(wordId: word.id, morphemeId: morphemeId)
      ,
    ]) {await insertion;}
    return id;
  }
  
  Future<void> updateWord(Word word) async {
    await _db.update("words", word.toMap(), where: "id = ?", whereArgs: [word.id]);
  }
  
  Future<void> deleteWord(int wordId) async {
    await _db.delete("word", where: "id = ?", whereArgs: [wordId]);
  }
  
  Future<List<int>> getWordSynonymIds(int wordId) async => [
    for (Map<String, Object?> synonym in await _db.query("wordSynonyms",
      where: "wordIdA = ?",
      whereArgs: [wordId],
      columns: ["wordIdB"]
    )) synonym["wordIdB"] as int
  ];
  
  Future<void> insertWordSynonym(int wordIdA, int wordIdB) async {
    await _db.insert("wordSynonyms", {
      "wordIdA": wordIdA,
      "wordIdB": wordIdB,
    });
    await _db.insert("wordSynonyms", {
      "wordIdA": wordIdB,
      "wordIdB": wordIdA,
    });
  }

  Future<void> deleteWordSynonym(int wordIdA, int wordIdB) async {
    await _db.delete("wordSynonyms",
      where: "wordIdA = ? AND wordIdB = ?",
      whereArgs: [wordIdA, wordIdB],
    );
    await _db.delete("wordSynonyms",
      where: "wordIdA = ? AND wordIdB = ?",
      whereArgs: [wordIdB, wordIdA],
    );
  }
  
  Future<List<int>> getWordCalqueIds(int wordId) async => [
    for (Map<String, Object?> synonym in await _db.query("wordCalques",
      where: "wordIdA = ?",
      whereArgs: [wordId],
      columns: ["wordIdB"]
    )) synonym["wordIdB"] as int
  ];
  
  Future<void> insertWordCalque(int wordIdA, int wordIdB) async {
    await _db.insert("wordCalques", {
      "wordIdA": wordIdA,
      "wordIdB": wordIdB,
    });
    await _db.insert("wordCalques", {
      "wordIdA": wordIdB,
      "wordIdB": wordIdA,
    });
  }

  Future<void> deleteWordCalque(int wordIdA, int wordIdB) async {
    await _db.delete("wordCalques",
      where: "wordIdA = ? AND wordIdB = ?",
      whereArgs: [wordIdA, wordIdB],
    );
    await _db.delete("wordCalques",
      where: "wordIdA = ? AND wordIdB = ?",
      whereArgs: [wordIdB, wordIdA],
    );
  }

  Future<List<int>> getWordComponentIds(int wordId) async => [
    for (Map<String, Object?> component in await _db.query("wordCompositions",
      where: "wordId = ?",
      whereArgs: [wordId],
      columns: ["morphemeId"]
    )) component["morphemeId"] as int
  ];
  
  Future<List<int>> getMorphemeProductIds(int morphemeId) async => [
    for (Map<String, Object?> product in await _db.query("wordCompositions",
      where: "morphemeId = ?",
      whereArgs: [morphemeId],
      columns: ["wordId"]
    )) product["wordId"] as int
  ];
  
  Future<void> insertWordComposition({required int wordId, required int morphemeId, int? position}) async {
    if (position == null) {
      Set<int> extantPositions = (await _db.query(
        'wordCompositions', columns: ['position'],
        where: 'wordId = ?', whereArgs: [wordId]
      )).map((component) => component['position'] as int).toSet();
      int i = 0;
      while (extantPositions.contains(i)) {
        i += 1;
      }
      position = i;
    }
    await _db.insert("wordCompositions", {
      "wordId": wordId,
      "morphemeId": morphemeId,
      "position": position,
    });
  }

  Future<void> deleteWordComposition({required int wordId, required int morphemeId}) async {
    await _db.delete("wordCompositions",
      where: "wordId = ? AND morphemeId = ?",
      whereArgs: [wordId, morphemeId],
    );
  }

  // characters

  Future<List<Character>> getCharacters({
    Map<String, Object?>? filter,
    int? limit,
    int? offset
  }) async => (await _db.query("characters",
      where: filter == null ? null : [for (String key in filter.keys) "$key = ?"].join(),
      whereArgs: filter?.values.toList(),
      columns: ["id", "form", "notes"],
      limit: limit,
      offset: offset,
    )).map((data) => Character(
      id: data["id"] as int,
      form: data["form"] as String,
      notes: data["notes"] as String,
    )).toList(growable: false);

  Future<void> getCharacterDetails(Character character) async {
    for (Future assignment in [
      getCharacterSynonyms(character.id).then((value) {
        character.synonyms = value;
      },),
      getCharacterMeaningIds(character.id, true).then((value) {
        character.definitiveMeanings = value;
      },),
      getCharacterMeaningIds(character.id, false).then((value) {
        character.tentativeMeanings = value;
      },),
      getCharacterPronunciations(character.id, null).then((value) {
        character.extantPronunciations = value;
      }),
      getCharacterPronunciations(character.id, true).then((value) {
        character.definitivePronunciations = value;
      }),
      getCharacterPronunciations(character.id, false).then((value) {
        character.tentativePronunciations = value;
      }),
      getCharacterComponents(character.id).then((value) {
        character.components = value;
      },),
      getCharacterProducts(character.id).then((value) {
        character.products = value;
      },),
    ]) {await assignment;}
    character.hasDetails = true;
  }

  Future<int> insertCharacter(Character character) async {
    int id = await _db.insert("characters", character.toMap());
    character.id = id;
    for (Future insertion in [
      for (int morphemeId in character.definitiveMeanings ?? [])
        insertCharacterMeaning(
          characterId: character.id,
          morphemeId: morphemeId,
          isDefinitive: true
        )
      ,
      for (int morphemeId in character.tentativeMeanings ?? [])
        insertCharacterMeaning(
          characterId: character.id,
          morphemeId: morphemeId,
          isDefinitive: false
        )
      ,
      for (String pronunciation in character.extantPronunciations ?? [])
        insertCharacterPronunciation(
          characterId: character.id,
          pronunciation: pronunciation,
          isDefinitive: null
        )
      ,
      for (String pronunciation in character.definitivePronunciations!)
        insertCharacterPronunciation(
          characterId: character.id,
          pronunciation: pronunciation,
          isDefinitive: true
        )
      ,
      for (String pronunciation in character.tentativePronunciations!)
        insertCharacterPronunciation(
          characterId: character.id,
          pronunciation: pronunciation,
          isDefinitive: false
        )
      ,
      for (int componentId in character.components ?? [])
        insertCharacterComposition(componentId: componentId, composedId: character.id)
      ,
      for (int productId in character.products ?? [])
        insertCharacterComposition(componentId: character.id, composedId: productId)
      ,
    ]) {await insertion;}
    return id;
  }

  Future<void> updateCharacter(Character character) async {
    await _db.update("characters", character.toMap(), where: "id = ?", whereArgs: [character.id]);
  }

  Future<void> deleteCharacter(int characterId) async {
    await _db.delete("character", where: "id = ?", whereArgs: [characterId]);
  }

  Future<List<int>> getCharacterMeaningIds(int characterId, bool isDefinitive) async => [
    for (Map<String, Object?> meaning in await _db.query("characterMeanings",
      where: "characterId = ? AND isDefinitive = ?",
      whereArgs: [characterId, isDefinitive?1:0],
      columns: ["morphemeId"],
    )) meaning["morphemeId"] as int
  ];

  Future<List<int>> getMorphemeTransliterationIds(int morphemeId, bool isDefinitive) async => [
    for (Map<String, Object?> transliteration in await _db.query("characterMeanings",
      where: "morphemeId = ? AND isDefinitive = ?",
      whereArgs: [morphemeId, isDefinitive?1:0],
      columns: ["characterId"],
    )) transliteration["characterId"] as int
  ];
  
  Future<void> insertCharacterMeaning({
    required int characterId, 
    required int morphemeId,
    required bool isDefinitive,
  }) async {
    await _db.insert("characterMeanings", {
      "characterId": characterId,
      "morphemeId": morphemeId,
      "isDefinitive": isDefinitive ? 1:0
    });
  }

  Future<void> deleteCharacterMeaning({
    required int characterId,
    required int morphemeId,
  }) async {
    await _db.delete("characterMeanings",
      where: "characterId = ? AND morphemeId = ?",
      whereArgs: [characterId, morphemeId]
    );
  }

  Future<List<String>> getCharacterPronunciations(int characterId, bool? isDefinitive) async => [
    for (Map<String, Object?> pronunciation in await _db.query("characterPronunciations",
      where: "characterId = ? AND isDefinitive = ?",
      whereArgs: [characterId, (isDefinitive == null) ? null : isDefinitive?1:0],
      columns: ["pronunciation"]
    )) pronunciation["pronunciation"] as String
  ];

  Future<void> insertCharacterPronunciation({
    required int characterId,
    required String pronunciation,
    required bool? isDefinitive,
  }) async {
    await _db.insert("characterPronunciations", {
      "characterId": characterId,
      "pronunciation": pronunciation,
      "isDefinitive": isDefinitive == null ? null : isDefinitive ? 1:0
    });
  }
  
  Future<void> deleteCharacterPronunciation({
    required int characterId,
    required String pronunciation,
  }) async {
    await _db.delete("characterPronunciations",
      where: "characterId = ? AND pronunciation = ?",
      whereArgs: [characterId, pronunciation],
    );
  }
  
  Future<List<int>> getCharacterComponents(int characterId) async => [
    for (Map<String, Object?> component in await _db.query("characterCompositions",
      where: "composedId = ?",
      whereArgs: [characterId],
      columns: ["componentId"]
    )) component["componentId"] as int
  ];

  Future<List<int>> getCharacterProducts(int characterId) async =>[
    for (Map<String, Object?> composed in await _db.query("characterCompositions",
      where: "componentId = ?",
      whereArgs: [characterId],
      columns: ["composedId"]
    )) composed["composedId"] as int
  ];

  Future<void> insertCharacterComposition({
    required int componentId,
    required int composedId,
  }) async {
    await _db.insert("characterCompositions", {
      "componentId": componentId,
      "composedId": composedId,
    });
  }

  Future<void> deleteCharacterComposition({
    required int componentId,
    required int composedId,
  }) async {
    await _db.delete("characterCompositions",
      where: "componentId = ? AND composedId = ?",
      whereArgs: [componentId, composedId],
    );
  }

  Future<List<int>> getCharacterSynonyms(int characterId) async => [
    for (Map<String, Object?> synonym in await _db.query("characterSynonyms",
      where: "characterIdA = ?",
      whereArgs: [characterId],
      columns: ["characterIdB"]
    )) synonym["characterIdB"] as int
  ];

  Future<void> insertCharacterSynonym(int characterIdA, int characterIdB) async {
    await _db.insert("characterSynonyms", {
      "characterIdA": characterIdA,
      "characterIdB": characterIdB,
    });
    await _db.insert("characterSynonyms", {
      "characterIdA": characterIdB,
      "characterIdB": characterIdA,
    });
  }

  Future<void> deleteCharacterSynonym(int characterIdA, int characterIdB) async {
    await _db.delete("characterSynonyms", 
      where: "characterIdA = ? AND characterIdB = ?",
      whereArgs: [characterIdA, characterIdB],
    );
    await _db.delete("characterSynonyms", 
      where: "characterIdA = ? AND characterIdB = ?",
      whereArgs: [characterIdB, characterIdA],
    );
  }
}