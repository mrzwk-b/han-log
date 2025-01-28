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
          "form TEXT NOT NULL UNIQUE, "
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
    List<Map<String, dynamic>> morphemes = await db.query("morphemes",
      where: filter == null ? null : [for (String key in filter.keys) "$key = ?"].join(),
      whereArgs: filter?.values.toList(),
      columns: ["id", "form", "notes"],
      limit: limit,
      offset: offset,
    );
    return List.generate(morphemes.length, (int i) => Morpheme(
      id: morphemes[i]["id"],
      form: morphemes[i]["form"],
      notes: morphemes[i]["notes"],
    ), growable: false);
  }

  Future<void> getMorphemeDetails(Morpheme morpheme) async {
    for (Future assignment in [
      getMorphemeSynonyms(morpheme.id).then((value) {morpheme.synonyms = value;},),
      getMorphemeDoublets(morpheme.id).then((value) {morpheme.doublets = value;},),
      getMorphemeTransliterations(morpheme.id, true).then((value) {morpheme.definitiveCharacters = value;},),
      getMorphemeTransliterations(morpheme.id, false).then((value) {morpheme.tentativeCharacters = value;},),
      getMorphemeProducts(morpheme.id).then((value) {morpheme.words = value;},),
    ]) {await assignment;}
  }

  Future<int> insertMorpheme(Morpheme morpheme) async {
    int id = await db.insert("morphemes", morpheme.toMap());
    morpheme.id = id;
    for (Future insertion in [
      for (Morpheme synonym in morpheme.synonyms ?? []) 
        insertMorphemeSynonym(morpheme.id, synonym.id)
      ,
      for (Morpheme doublet in morpheme.doublets ?? [])
        insertMorphemeDoublet(morpheme.id, doublet.id)
      ,
      for (Character character in morpheme.definitiveCharacters ?? [])
        insertCharacterMeaning(characterId: character.id, morphemeId: morpheme.id, isDefinitive: true)
      ,
      for (Character character in morpheme.tentativeCharacters ?? [])
        insertCharacterMeaning(characterId: character.id, morphemeId: morpheme.id, isDefinitive: false)
      ,
      for (Word word in morpheme.words ?? [])
        insertWordComposition(word.id, morpheme.id)
      ,
    ]) {await insertion;}
    return id;
  }
  
  Future<void> updateMorpheme(Morpheme morpheme) async {
    await db.update("morphemes", morpheme.toMap(), where: "id = ?", whereArgs: [morpheme.id]);
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
      getWordComponents(word.id).then((value) {word.components = value;},),
      getWordSynonyms(word.id).then((value) {word.synonyms = value;},),
      getWordCalques(word.id).then((value) {word.calques = value;},),
    ]) {await assignment;}
  }

  Future<int> insertWord(Word word) async {
    int id = await db.insert("words", word.toMap());
    word.id = id;
    for (Future insertion in [
      for (Word synonym in word.synonyms ?? []) 
        insertWordSynonym(word.id, synonym.id)
      ,
      for (Word calque in word.calques ?? [])
        insertWordCalque(word.id, calque.id)
      ,
      for (Morpheme morpheme in word.components ?? [])
        insertWordComposition(word.id, morpheme.id)
      ,
    ]) {await insertion;}
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
  
  Future<List<Word>> getMorphemeProducts(int morphemeId) async {
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
      columns: ["id", "form", "notes"],
      limit: limit,
      offset: offset,
    );
    return List.generate(chars.length, (int i) => Character(
      id: chars[i]["id"],
      form: chars[i]["form"],
      notes: chars[i]["notes"],
    ), growable: false);
  }

  Future<void> getCharacterDetails(Character character) async {
    for (Future assignment in [
      getCharacterMeanings(character.id, true).then((value) {
        character.definitiveMeanings = value;
      },),
      getCharacterMeanings(character.id, false).then((value) {
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
  }

  Future<int> insertCharacter(Character character) async {
    int id = await db.insert("characters", character.toMap());
    character.id = id;
    for (Future insertion in [
      for (Morpheme morpheme in character.definitiveMeanings ?? [])
        insertCharacterMeaning(
          characterId: character.id,
          morphemeId: morpheme.id,
          isDefinitive: true
        )
      ,
      for (Morpheme morpheme in character.tentativeMeanings ?? [])
        insertCharacterMeaning(
          characterId: character.id,
          morphemeId: morpheme.id,
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
      for (Character component in character.components ?? [])
        insertCharacterComposition(componentId: component.id, composedId: character.id)
      ,
      for (Character product in character.products ?? [])
        insertCharacterComposition(componentId: character.id, composedId: product.id)
      ,
    ]) {await insertion;}
    return id;
  }

  Future<void> updateCharacter(Character character) async {
    await db.update("characters", character.toMap(), where: "id = ?", whereArgs: [character.id]);
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
          columns: ["morphemeId"],
        )) getMorphemes(filter: {"id": meaning["morphemeId"]})
      ]) (await morpheme).single
    ];
  }

  Future<List<Character>> getMorphemeTransliterations(int morphemeId, bool isDefinitive) async {
    return [
      for (Future<List<Character>> character in [
        for (Map<String, dynamic> transliteration in await db.query("characterMeanings",
          where: "morphemeId = ? AND isDefinitive = ?",
          whereArgs: [morphemeId, isDefinitive?1:0],
          columns: ["characterId"],
        )) getCharacters(filter: {"id": transliteration["characterId"]})
      ]) (await character).single
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

  Future<List<String>> getCharacterPronunciations(int characterId, bool? isDefinitive) async {
    return [
      for (Map<String, dynamic> pronunciation in await db.query("characterPronunciations",
        where: "characterId = ? AND isDefinitive = ?",
        whereArgs: [characterId, (isDefinitive == null) ? null : isDefinitive?1:0],
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