import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:app/data/models/character.dart';
import 'package:app/data/models/morpheme.dart';
import 'package:app/data/models/word.dart';

class DbHelper {
  late Database db;

  DbHelper._internal();
  static final DbHelper helper = DbHelper._internal();
  factory DbHelper() => helper;

  Future<Database> openDb() async {
    db = await openDatabase(
      join(await getDatabasesPath(), 'han_log.db'),
      onCreate: (database, version) async {        
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
          "UNIQUE(morphemeIdA, morphemeIdB), "
          "FOREIGN KEY(morphemeIdA) REFERENCES morphemes(id) ON DELETE CASCADE, "
          "FOREIGN KEY(morphemeIdB) REFERENCES morphemes(id) ON DELETE CASCADE"
          ") WITHOUT ROWID"
        );
        await database.execute(
          "CREATE TABLE morphemeDoublets("
          "morphemeIdA INTEGER NOT NULL, "
          "morphemeIdB INTEGER NOT NULL, "
          "UNIQUE(morphemeIdA, morphemeIdB), "
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
          "UNIQUE(wordId, position), "
          "FOREIGN KEY(wordId) REFERENCES words(id) ON DELETE CASCADE, "
          "FOREIGN KEY(morphemeId) REFERENCES morphemes(id) ON DELETE CASCADE"
          ") WITHOUT ROWID"
        );
        await database.execute(
          "CREATE TABLE wordSynonyms("
          "wordIdA INTEGER NOT NULL, "
          "wordIdB INTEGER NOT NULL, "
          "UNIQUE(wordIdA, wordIdB), "
          "FOREIGN KEY(wordIdA) REFERENCES words(id) ON DELETE CASCADE, "
          "FOREIGN KEY(wordIdB) REFERENCES words(id) ON DELETE CASCADE"
          ") WITHOUT ROWID"
        );
        await database.execute(
          "CREATE TABLE wordCalques("
          "wordIdA INTEGER NOT NULL, "
          "wordIdB INTEGER NOT NULL, "
          "UNIQUE(wordIdA, wordIdB), "
          "FOREIGN KEY(wordIdA) REFERENCES words(id) ON DELETE CASCADE, "
          "FOREIGN KEY(wordIdB) REFERENCES words(id) ON DELETE CASCADE"
          ") WITHOUT ROWID"
        );
        // characters
        await database.execute(
          "CREATE TABLE characters("
          "id INTEGER PRIMARY KEY AUTOINCREMENT, "
          "glyph TEXT NOT NULL UNIQUE, "
          "notes TEXT NOT NULL)"
        );
        await database.execute(
          "CREATE TABLE characterMeanings("
          "isDefinitive INTEGER NOT NULL, "
          "characterId INTEGER NOT NULL, "
          "morphemeId INTEGER NOT NULL, "
          "UNIQUE(characterId, morphemeId), "
          "FOREIGN KEY(characterId) REFERENCES characters(id) ON DELETE CASCADE, "
          "FOREIGN KEY(morphemeId) REFERENCES morphemes(id) ON DELETE CASCADE"
          ") WITHOUT ROWID"
        );
        await database.execute(
          "CREATE TABLE characterPronunciations("
          "isDefinitive INTEGER, "
          "pronunciation TEXT NOT NULL, "
          "characterId INTEGER NOT NULL, "
          "FOREIGN KEY(characterId) REFERENCES characters(id) ON DELETE CASCADE"
          ") WITHOUT ROWID"
        );
        await database.execute(
          "CREATE TABLE characterCompositions("
          "componentId INTEGER NOT NULL, "
          "composedId INTEGER NOT NULL, "
          "FOREIGN KEY(componentId) REFERENCES characters(id) ON DELETE CASCADE, "
          "FOREIGN KEY(composedId) REFERENCES characters(id) ON DELETE CASCADE"
          ") WITHOUT ROWID"
        );
        await database.execute(
          "CREATE TABLE characterSynonyms("
          "characterIdA INTEGER NOT NULL, "
          "characterIdB INTEGER NOT NULL, "
          "FOREIGN KEY(characterIdA) REFERENCES characters(id) ON DELETE CASCADE, "
          "FOREIGN KEY(characterIdB) REFERENCES characters(id) ON DELETE CASCADE"
          ") WITHOUT ROWID"
        );
      },
      version: 1
    );
    return db;
  }

  // morphemes

  Future<List<Morpheme>> getMorphemes({
    Map<String, dynamic>? filter,
    int? limit,
    int? offset
  }) async {
    List<Map<String, dynamic>> morphs = await db.query("morphemes",
      where: filter == null ? null : [for (String key in filter.keys) "$key = ?"].join(),
      whereArgs: filter?.values.toList(),
      columns: ["id", "form", "notes"],
      limit: limit,
      offset: offset,
    );
    return List.generate(morphs.length, (int i) => Morpheme(
      id: morphs[i]["id"],
      form: morphs[i]["form"],
      notes: morphs[i]["notes"],
    ), growable: false);
  }

  Future<void> getMorphemeDetails(Morpheme morph) async {
    for (Future assignment in [
      db.query("morphemeSynonyms",
        where: "morphemeIdA = ? OR morphemeIdB = ?",
        whereArgs: [morph.id] // we may need an extra copy of morph.id in the list, not sure if argument reuse works how i expect
      ).then((value) {morph.synonymIds = 
        value.map((item) => (item["morphemeIdB"] == morph.id ? 
          item["morphemeIdA"] : 
          item["morphemeIdB"]
        ) as int).toList()
      ;}),
      db.query("morphemeDoublets",
        where: "morphemeIdA = ? OR morphemeIdB = ?",
        whereArgs: [morph.id] // we may need an extra copy of morph.id in the list, not sure if argument reuse works how i expect
      ).then((value) {morph.doubletIds = 
        value.map((item) => (item["morphemeIdB"] == morph.id ? 
          item["morphemeIdA"] : 
          item["morphemeIdB"]
        ) as int).toList()
      ;}),
      db.query("characterMeanings",
        where: "morphemeId = ? AND isDefinitive = 1",
        whereArgs: [morph.id],
        columns: ["characterId"],
      ).then((value) {morph.definitiveCharacterIds = 
        value.map((item) => item["characterId"] as int).toList()
      ;}),
      db.query("characterMeanings",
        where: "morphemeId = ? AND isDefinitive = 0",
        whereArgs: [morph.id],
        columns: ["characterId"],
      ).then((value) {morph.tentativeCharacterIds = 
        value.map((item) => item["characterId"] as int).toList()
      ;}),
      db.query("wordCompositions",
        where: "morphemeId = ?",
        whereArgs: [morph.id],
        columns: ["wordId"]
      ).then((value) {morph.wordIds =
        value.map((item) => item["wordId"] as int).toList()
      ;}),
    ]) {await assignment;}
  }

  Future<int> insertMorpheme(Morpheme morph) async {
    int id = await db.insert("morphemes", morph.toMap());
    morph.id = id;
    if (morph.synonymIds != null) {
      for (int synonymId in morph.synonymIds!) {
        await db.insert("morphemeSynonyms", {
          "morphemeIdA": morph.id,
          "morphemeIdB": synonymId,
        });
      }
    }
    if (morph.doubletIds != null) {
      for (int doubletId in morph.doubletIds!) {
        await db.insert("morphemeDoublets", {
          "morphemeIdA": morph.id,
          "morphemeIdB": doubletId,
        });
      }
    }
    if (morph.definitiveCharacterIds != null) {
      for (int charId in morph.definitiveCharacterIds!) {
        await db.insert("characterMeanings", {
          "isDefinitive": 1,
          "characterId": charId,
          "morphemeId": morph.id,
        });
      }
    }
    if (morph.tentativeCharacterIds != null) {
      for (int charId in morph.tentativeCharacterIds!) {
        await db.insert("characterMeanings", {
          "isDefinitive": 0,
          "characterId": charId,
          "morphemeId": morph.id,
        });
      }
    }
    if (morph.wordIds != null) {
      for (int wordId in morph.wordIds!) {
        await db.insert("wordCompositions", {
          "wordId": wordId,
          "morphemeId": morph.id,
        });
      }
    }
    return id;
  }
  
  Future<void> updateMorpheme(Morpheme morph) async {
    await db.update("morphemes", morph.toMap(), where: "id = ?", whereArgs: [morph.id]);
  }
  
  Future<void> deleteMorpheme(int morphemeId) async {
    await db.delete("morpheme", where: "id = ?", whereArgs: [morphemeId]);
  }
  
  Future<List<Morpheme>> getMorphemeSynonyms(int morphemeId) async {
    return [
      for(Future<List<Morpheme>> morpheme in [
        for (Map<String, dynamic> synonym in await db.query("morphemeSynonyms",
          where: "morphemeIdA = ?",
          whereArgs: [morphemeId],
          columns: ["morphemeIdB"]
        )) getMorphemes(filter: {"id": synonym["morphemeIdB"]})
      ]) (await morpheme).single
    ];
  }

  Future<void> insertMorphemeSynonym(int morphemeIdA, int morphemeIdB) async {
    await db.insert("morphemeSynonyms", {
      "morphemeIdA": morphemeIdA,
      "morphemeIdB": morphemeIdB,
    });
    await db.insert("morphemeSynonyms", {
      "morphemeIdA": morphemeIdB,
      "morphemeIdB": morphemeIdA,
    });
  }

  Future<void> deleteMorphemeSynonym(int morphemeIdA, int morphemeIdB) async {
    await db.delete("morphemeSynonyms",
      where: "morphemeIdA = ? AND morphemeIdB = ?",
      whereArgs: [morphemeIdA, morphemeIdB],
    );
    await db.delete("morphemeSynonyms",
      where: "morphemeIdA = ? AND morphemeIdB = ?",
      whereArgs: [morphemeIdB, morphemeIdA],
    );
  }
  
  Future<List<Morpheme>> getMorphemeDoublets(int morphemeId) async {
    return [
      for(Future<List<Morpheme>> morpheme in [
        for (Map<String, dynamic> doublet in await db.query("morphemeDoublets",
          where: "morphemeIdA = ?",
          whereArgs: [morphemeId],
          columns: ["morphemeIdB"]
        )) getMorphemes(filter: {"id": doublet["morphemeIdB"]})
      ]) (await morpheme).single
    ];
  }

  Future<void> insertMorphemeDoublet(int morphemeIdA, int morphemeIdB) async {
    await db.insert("morphemeDoublets", {
      "morphemeIdA": morphemeIdA,
      "morphemeIdB": morphemeIdB,
    });
    await db.insert("morphemeDoublets", {
      "morphemeIdA": morphemeIdB,
      "morphemeIdB": morphemeIdA,
    });
  }

  Future<void> deleteMorphemeDoublet(int morphemeIdA, int morphemeIdB) async {
    await db.delete("morphemeDoublets",
      where: "morphemeIdA = ? AND morphemeIdB = ?",
      whereArgs: [morphemeIdA, morphemeIdB],
    );
    await db.delete("morphemeDoublets",
      where: "morphemeIdA = ? AND morphemeIdB = ?",
      whereArgs: [morphemeIdB, morphemeIdA],
    );
  }

  // words

  Future<List<Word>> getWords({
    Map<String, dynamic>? filter,
    int? limit,
    int? offset
  }) async {
    List<Map<String, dynamic>> words = await db.query("words",
      where: filter == null ? null : [for (String key in filter.keys) "$key = ?"].join(),
      whereArgs: filter?.values.toList(),
      columns: ["id", "form", "notes"],
      limit: limit,
      offset: offset,
    );
    return List.generate(words.length, (int i) => Word(
      id: words[i]["id"],
      form: words[i]["form"],
      notes: words[i]["notes"],
    ), growable: false);
  }

  Future<void> getWordDetails(Word word) async {
    for (Future assignment in [      
      db.query("wordCompositions", 
        where: "wordId = ?",
        whereArgs: [word.id],
      ).then((value) {word.componentIds =
        value.map((item) => item["morphemeId"] as int).toList()
      ;}),
      db.query("wordSynonyms",
        where: "wordIdA = ? OR wordIdB = ?",
        whereArgs: [word.id]
      ).then((value) {word.synonymIds = 
        value.map((item) => (item["wordIdB"] == word.id ? 
          item["wordIdA"] : 
          item["wordIdB"]
        ) as int).toList()
      ;}),
      db.query("wordCalques",
        where: "wordIdA = ? OR wordIdB = ?",
        whereArgs: [word.id]
      ).then((value) {word.calqueIds = 
        value.map((item) => (item["wordIdB"] == word.id ? 
          item["wordIdA"] : 
          item["wordIdB"]
        ) as int).toList()
      ;}),
    ]) {await assignment;}
  }

  Future<int> insertWord(Word word) async {
    int id = await db.insert("words", word.toMap());
    word.id = id;
    if (word.synonymIds != null) {
      for (int synonymId in word.synonymIds!) {
        await db.insert("wordSynonyms", {
          "wordIdA": word.id,
          "wordIdB": synonymId,
        });
      }
    }
    if (word.calqueIds != null) {
      for (int doubletId in word.calqueIds!) {
        await db.insert("wordCalques", {
          "wordIdA": word.id,
          "wordIdB": doubletId,
        });
      }
    }
    if (word.componentIds != null) {
      for (int morphemeId in word.componentIds!) {
        await db.insert("wordCompositions", {
          "morphemeId": morphemeId,
          "wordId": word.id,
        });
      }
    }
    return id;
  }
  
  Future<void> updateWord(Word word) async {
    await db.update("words", word.toMap(), where: "id = ?", whereArgs: [word.id]);
  }
  
  Future<void> deleteWord(int wordId) async {
    await db.delete("word", where: "id = ?", whereArgs: [wordId]);
  }
  
  Future<List<Word>> getWordSynonyms(int wordId) async {
    return [
      for(Future<List<Word>> word in [
        for (Map<String, dynamic> synonym in await db.query("wordSynonyms",
          where: "wordIdA = ?",
          whereArgs: [wordId],
          columns: ["wordIdB"]
        )) getWords(filter: {"id": synonym["wordIdB"]})
      ]) (await word).single
    ];
  }

  Future<void> insertWordSynonym(int wordIdA, int wordIdB) async {
    await db.insert("wordSynonyms", {
      "wordIdA": wordIdA,
      "wordIdB": wordIdB,
    });
    await db.insert("wordSynonyms", {
      "wordIdA": wordIdB,
      "wordIdB": wordIdA,
    });
  }

  Future<void> deleteWordSynonym(int wordIdA, int wordIdB) async {
    await db.delete("wordSynonyms",
      where: "wordIdA = ? AND wordIdB = ?",
      whereArgs: [wordIdA, wordIdB],
    );
    await db.delete("wordSynonyms",
      where: "wordIdA = ? AND wordIdB = ?",
      whereArgs: [wordIdB, wordIdA],
    );
  }
  
  Future<List<Word>> getWordCalques(int wordId) async {
    return [
      for(Future<List<Word>> word in [
        for (Map<String, dynamic> synonym in await db.query("wordCalques",
          where: "wordIdA = ?",
          whereArgs: [wordId],
          columns: ["wordIdB"]
        )) getWords(filter: {"id": synonym["wordIdB"]})
      ]) (await word).single
    ];
  }
  
  Future<void> insertWordCalque(int wordIdA, int wordIdB) async {
    await db.insert("wordCalques", {
      "wordIdA": wordIdA,
      "wordIdB": wordIdB,
    });
    await db.insert("wordCalques", {
      "wordIdA": wordIdB,
      "wordIdB": wordIdA,
    });
  }

  Future<void> deleteWordCalque(int wordIdA, int wordIdB) async {
    await db.delete("wordCalques",
      where: "wordIdA = ? AND wordIdB = ?",
      whereArgs: [wordIdA, wordIdB],
    );
    await db.delete("wordCalques",
      where: "wordIdA = ? AND wordIdB = ?",
      whereArgs: [wordIdB, wordIdA],
    );
  }

  Future<List<Morpheme>> getWordComponents(int wordId) async {
    return [
      for(Future<List<Morpheme>> morpheme in [
        for (Map<String, dynamic> component in await db.query("wordCompositions",
          where: "wordId = ?",
          whereArgs: [wordId],
          columns: ["morphemeId"]
        )) getMorphemes(filter: {"id": component["morphemeId"]})
      ]) (await morpheme).single
    ];
  }
  
  Future<List<Word>> getmorphemeProducts(int morphemeId) async {
    return [
      for(Future<List<Word>> word in [
        for (Map<String, dynamic> product in await db.query("wordCompositions",
          where: "morphemeId = ?",
          whereArgs: [morphemeId],
          columns: ["wordId"]
        )) getWords(filter: {"id": product["wordId"]})
      ]) (await word).single
    ];
  }
  
  Future<void> insertWordComposition(int wordId, int morphemeId, {int? position}) async {
    await db.insert("wordCompositions", {
      "wordId": wordId,
      "morphemeId": morphemeId,
      "position": position,
    });
  }

  Future<void> deleteWordComposition(int wordId, int morphemeId) async {
    await db.delete("wordCompositions",
      where: "wordId = ? AND morphemeId = ?",
      whereArgs: [wordId, morphemeId],
    );
  }

  // characters

  Future<List<Character>> getCharacters({
    Map<String, dynamic>? filter,
    int? limit,
    int? offset
  }) async {
    List<Map<String, dynamic>> chars = await db.query("characters",
      where: filter == null ? null : [for (String key in filter.keys) "$key = ?"].join(),
      whereArgs: filter?.values.toList(),
      columns: ["id", "glyph", "notes"],
      limit: limit,
      offset: offset,
    );
    return List.generate(chars.length, (int i) => Character(
      id: chars[i]["id"],
      form: chars[i]["glyph"],
      notes: chars[i]["notes"],
    ), growable: false);
  }

  Future<void> getCharacterDetails(Character char) async {
    for (Future assignment in [
      db.query("characterMeanings", 
        where: "characterId = ? AND isDefinitive = 0",
        whereArgs: [char.id],
        columns: ["morphemeId"],
      ).then((value) {char.tentativeMeaningIds = 
        value.map((item) => item["morphemeId"] as int).toList()
      ;},),
      db.query("characterMeanings", 
        where: "characterId = ? AND isDefinitive = 1",
        whereArgs: [char.id],
        columns: ["morphemeId"],
      ).then((value) {char.definitiveMeaningIds = 
        value.map((item) => item["morphemeId"] as int).toList()
      ;},),
      db.query("characterPronunciations", 
        where: "characterId = ? AND isDefinitive = NULL",
        whereArgs: [char.id],
        columns: ["pronunciation"],
      ).then((value) {char.extantPronunciations = 
        value.map((item) => item["pronunciation"] as String).toList()
      ;},),
      db.query("characterPronunciations", 
        where: "characterId = ? AND isDefinitive = 0",
        whereArgs: [char.id],
        columns: ["pronunciation"],
      ).then((value) {char.tentativePronunciations = 
        value.map((item) => item["pronunciation"] as String).toList()
      ;},),
      db.query("characterPronunciations", 
        where: "characterId = ? AND isDefinitive = 1",
        whereArgs: [char.id],
        columns: ["pronunciation"],
      ).then((value) {char.definitivePronunciations =
        value.map((item) => item["pronunciation"] as String).toList()
      ;}),
      db.query("characterCompositions", 
        where: "composedId = ?",
        whereArgs: [char.id],
        columns: ["componentId"],
      ).then((value) {char.componentIds = 
        value.map((item) => item["componentId"] as int).toList()
      ;},),
      db.query("characterCompositions", 
        where: "componentId = ?",
        whereArgs: [char.id],
        columns: ["composedId"],
      ).then((value) {char.derivedIds = 
      value.map((item) => item["composedId"] as int).toList()
      ;}),
    ]) {await assignment;}
  }

  Future<int> insertCharacter(Character char) async {
    int id = await db.insert("characters", char.toMap());
    char.id = id;
    if (char.definitiveMeaningIds != null) {
      for (int morphemeId in char.definitiveMeaningIds!) {
        await db.insert("characterMeanings", {
          "isDefinitive": 1,
          "characterId": char.id,
          "morphemeId": morphemeId,
        });
      }
    }
    if (char.tentativeMeaningIds != null) {
      for (int morphemeId in char.tentativeMeaningIds!) {
        await db.insert("characterMeanings", {
          "isDefinitive": 0,
          "characterId": char.id,
          "morphemeId": morphemeId,
        });
      }
    }
    if (char.extantPronunciations != null) {
      for (String pronunciation in char.extantPronunciations!) {
        await db.insert("characterPronunciations", {
          "isDefinitive": null,
          "characterId": char.id,
          "pronunciation": pronunciation,
        });
      }
    }
    if (char.definitivePronunciations != null) {
      for (String pronunciation in char.definitivePronunciations!) {
        await db.insert("characterPronunciations", {
          "isDefinitive": 1,
          "characterId": char.id,
          "pronunciation": pronunciation,
        });
      }
    }
    if (char.tentativePronunciations != null) {
      for (String pronunciation in char.tentativePronunciations!) {
        await db.insert("characterPronunciations", {
          "isDefinitive": 0,
          "characterId": char.id,
          "pronunciation": pronunciation,
        });
      }
    }
    if (char.componentIds != null) {
      for (int componentId in char.componentIds!) {
        await db.insert("characterCompositions", {
          "composedId": char.id,
          "componentId": componentId,
        });
      }
    }
    if (char.derivedIds != null) {
      for (int composedId in char.derivedIds!) {
        await db.insert("characterCompositions", {
          "componentId": char.id,
          "composedId": composedId,
        });
      }
    }    
    return id;
  }

  Future<void> updateCharacter(Character char) async {
    await db.update("characters", char.toMap(), where: "id = ?", whereArgs: [char.id]);
  }

  Future<void> deleteCharacter(int characterId) async {
    await db.delete("character", where: "id = ?", whereArgs: [characterId]);
  }

  Future<List<Morpheme>> getCharacterMeanings(int characterId, bool isDefinitive) async {
    return [
      for(Future<List<Morpheme>> morpheme in [
        for (Map<String, dynamic> meaning in await db.query("characterMeanings",
          where: "characterId = ? AND isDefinitive = ?",
          whereArgs: [characterId, isDefinitive?1:0],
          columns: ["morphemeId"]
        )) getMorphemes(filter: {"id": meaning["morphemeId"]})
      ]) (await morpheme).single
    ];
  }

  Future<void> insertCharacterMeaning({
    required int characterId, 
    required int morphemeId,
    required bool isDefinitive,
  }) async {
    await db.insert("characterMeanings", {
      "characterId": characterId,
      "morphemeId": morphemeId,
      "isDefinitive": isDefinitive ? 1:0
    });
  }

  Future<void> deleteCharacterMeaning({
    required int characterId,
    required int morphemeId,
  }) async {
    await db.delete("characterMeanings",
      where: "characterId = ? AND morphemeId = ?",
      whereArgs: [characterId, morphemeId]
    );
  }

  Future<List<String>> getCharacterPronunciations(int characterId, bool isDefinitive) async {
    return [
      for (Map<String, dynamic> pronunciation in await db.query("characterPronunciations",
        where: "characterId = ? AND isDefinitive = ?",
        whereArgs: [characterId, isDefinitive?1:0],
        columns: ["pronunciation"]
      )) pronunciation["pronunciation"]
    ];
  }

  Future<void> insertCharacterPronunciation({
    required int characterId,
    required String pronunciation,
    required bool? isDefinitive,
  }) async {
    await db.insert("characterPronunciations", {
      "characterId": characterId,
      "pronunciation": pronunciation,
      "isDefinitive": isDefinitive == null ? null : isDefinitive ? 1:0
    });
  }
  
  Future<void> deleteCharacterPronunciation({
    required int characterId,
    required String pronunciation,
  }) async {
    await db.delete("characterPronunciations",
      where: "characterId = ? AND pronunciation = ?",
      whereArgs: [characterId, pronunciation],
    );
  }
  
  Future<List<Character>> getCharacterComponents(int characterId) async {
    return [
      for(Future<List<Character>> character in [
        for (Map<String, dynamic> component in await db.query("characterCompositions",
          where: "composedId = ?",
          whereArgs: [characterId],
          columns: ["componentId"]
        )) getCharacters(filter: {"id": component["componentId"]})
      ]) (await character).single
    ];
  }
  
  Future<List<Character>> getCharacterProducts(int characterId) async {
    return [
      for(Future<List<Character>> character in [
        for (Map<String, dynamic> composed in await db.query("characterCompositions",
          where: "componentId = ?",
          whereArgs: [characterId],
          columns: ["composedId"]
        )) getCharacters(filter: {"id": composed["composedId"]})
      ]) (await character).single
    ];
  }

  Future<void> insertCharacterComposition({
    required int componentId,
    required int composedId,
  }) async {
    await db.insert("characterCompositions", {
      "componentId": componentId,
      "composedId": composedId,
    });
  }

  Future<void> deleteCharacterComposition({
    required int componentId,
    required int composedId,
  }) async {
    await db.delete("characterCompositions",
      where: "componentId = ? AND composedId = ?",
      whereArgs: [componentId, composedId],
    );
  }

  Future<List<Character>> getCharacterSynonyms(int characterId) async {
    return [
      for(Future<List<Character>> character in [
        for (Map<String, dynamic> synonym in await db.query("characterSynonyms",
          where: "characterIdA = ?",
          whereArgs: [characterId],
          columns: ["characterIdB"]
        )) getCharacters(filter: {"id": synonym["characterIdB"]})
      ]) (await character).single
    ];
  }

  Future<void> insertCharacterSynonym(int characterIdA, int characterIdB) async {
    await db.insert("characterSynonyms", {
      "characterIdA": characterIdA,
      "characterIdB": characterIdB,
    });
    await db.insert("characterSynonyms", {
      "characterIdA": characterIdB,
      "characterIdB": characterIdA,
    });
  }

  Future<void> deleteCharacterSynonym(int characterIdA, int characterIdB) async {
    await db.delete("characterSynonyms", 
      where: "characterIdA = ? AND characterIdB = ?",
      whereArgs: [characterIdA, characterIdB],
    );
    await db.delete("characterSynonyms", 
      where: "characterIdA = ? AND characterIdB = ?",
      whereArgs: [characterIdB, characterIdA],
    );
  }
}