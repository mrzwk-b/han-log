import 'package:app/data/db_helper.dart';
import 'package:app/data/models/morpheme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  DbHelper dbHelper = DbHelper();
  Database db = await dbHelper.openDb();
  tearDown(() async {
    for (Future deletion in [
      db.delete('morphemes'),
      db.delete('words'),
      db.delete('characters'),
      // all relationship tables have ON DELETE CASCADE
      // so no other deletions should be necessary
    ]) {await deletion;}
  });

  group('morpheme:', () {
    group('getMorphemes()', () {
      test('one item in db', () async {
        await db.insert('morphemes', {
          'id': 1,
          'form': 'one',
          'notes': 'the second natural number (after zero)'
        });
        List<Morpheme> morphemes = await dbHelper.getMorphemes();

        expect(morphemes, hasLength(1));
        Morpheme morpheme = morphemes.single;
        expect(morpheme.id, 1);
        expect(morpheme.form, 'one');
        expect(morpheme.notes, 'the second natural number (after zero)');
      });
      test('get one item of several using filter', () async {
        await db.insert('morphemes', {
          'id': 1,
          'form': 'one',
          'notes': 'number'
        });
        await db.insert('morphemes', {
          'id': 2,
          'form': 'two',
          'notes': 'number'
        });
        await db.insert('morphemes', {
          'id': 3,
          'form': 'three',
          'notes': 'number'
        });
        List<Morpheme> morphemes;
        Morpheme morpheme;

        morphemes = await dbHelper.getMorphemes(filter: {'form': 'one'});
        expect(morphemes, hasLength(1));
        morpheme = morphemes.single;
        expect(morpheme.id, 1);
        expect(morpheme.form, 'one');

        morphemes = await dbHelper.getMorphemes(filter: {'id': 2});
        expect(morphemes, hasLength(1));
        morpheme = morphemes.single;
        expect(morpheme.id, 2);
        expect(morpheme.form, 'two');
      });
      test('get several items', () async {
        await db.insert('morphemes', {
          'id': 1,
          'form': 'one',
          'notes': 'number'
        });
        await db.insert('morphemes', {
          'id': 2,
          'form': 'two',
          'notes': 'number'
        });
        await db.insert('morphemes', {
          'id': 3,
          'form': 'three',
          'notes': 'number'
        });
        List<Morpheme> morphemes = await dbHelper.getMorphemes();

        expect(morphemes, hasLength(3));
        expect(morphemes, containsAll([
          Morpheme(id: 1, form: 'one', notes: 'number'),
          Morpheme(id: 2, form: 'two', notes: 'number'),
          Morpheme(id: 3, form: 'three', notes: 'number'),
        ]));
      });
      test('limit > # stored', () async {
        await db.insert('morphemes', {
          'id': 1,
          'form': 'one',
          'notes': 'number'
        });
        await db.insert('morphemes', {
          'id': 2,
          'form': 'two',
          'notes': 'number'
        });
        await db.insert('morphemes', {
          'id': 3,
          'form': 'three',
          'notes': 'number'
        });
        List<Morpheme> morphemes = await dbHelper.getMorphemes(limit: 4);

        expect(morphemes, hasLength(3));
      });
      test('offset >= # stored', () async {
        await db.insert('morphemes', {
          'id': 1,
          'form': 'one',
          'notes': 'number'
        });
        await db.insert('morphemes', {
          'id': 2,
          'form': 'two',
          'notes': 'number'
        });
        await db.insert('morphemes', {
          'id': 3,
          'form': 'three',
          'notes': 'number'
        });
        List<Morpheme> morphemes = await dbHelper.getMorphemes(offset: 3);

        expect(morphemes, hasLength(0));
      });
    });
    group('getMorphemeDetails()', () {
      test('synonyms', () async {
        await db.insert('morphemes', {
          'id': 1,
          'form': 'one',
          'notes': 'english'
        });
        await db.insert('morphemes', {
          'id': 2,
          'form': 'mono',
          'notes': 'greek'
        });
        await db.insert('morphemes', {
          'id': 3,
          'form': 'un',
          'notes': 'latin'
        });
        await db.insert('morphemes', {
          'id': 4,
          'form': 'two',
          'notes': 'english',
        });
        await db.insert('morphemes', {
          'id': 5,
          'form': 'di',
          'notes': 'latin',
        });
        await db.insert('morphemeSynonyms', {
          'morphemeIdA': 1,
          'morphemeIdB': 2,
        });
        await db.insert('morphemeSynonyms', {
          'morphemeIdA': 2,
          'morphemeIdB': 1,
        });
        await db.insert('morphemeSynonyms', {
          'morphemeIdA': 2,
          'morphemeIdB': 3,
        });
        await db.insert('morphemeSynonyms', {
          'morphemeIdA': 3,
          'morphemeIdB': 2,
        });
        await db.insert('morphemeSynonyms', {
          'morphemeIdA': 3,
          'morphemeIdB': 1,
        });
        await db.insert('morphemeSynonyms', {
          'morphemeIdA': 1,
          'morphemeIdB': 3,
        });
        await db.insert('morphemeSynonyms', {
          'morphemeIdA': 4,
          'morphemeIdB': 5,
        });
        await db.insert('morphemeSynonyms', {
          'morphemeIdA': 5,
          'morphemeIdB': 4,
        });

        List<int> synonymIds = await dbHelper.getMorphemeSynonymIds(1);

        expect(synonymIds, hasLength(2));
        expect(synonymIds, containsAll([2, 3]));
        expect(synonymIds, isNot(contains(1)));
        expect(synonymIds, isNot(contains(anyOf(4, 5))));
      });
      test('doublets', () async {
        await db.insert('morphemes', {
          'id': 1,
          'form': 'pyre',
          'notes': 'greek',
        });
        await db.insert('morphemes', {
          'id': 2,
          'form': 'fire',
          'notes': 'english',
        });
        await db.insert('morphemes', {
          'id': 3,
          'form': 'host',
          'notes': 'of an event'
        });
        await db.insert('morphemes', {
          'id': 4,
          'form': 'guest',
          'notes': 'at an event'
        });
        await db.insert('morphemes', {
          'id': 5,
          'form': 'ire',
          'notes': 'wrath',
        });
        await db.insert('morphemeDoublets', {
          'morphemeIdA': 1,
          'morphemeIdB': 2,
        });
        await db.insert('morphemeDoublets', {
          'morphemeIdA': 2,
          'morphemeIdB': 1,
        });
        await db.insert('morphemeDoublets', {
          'morphemeIdA': 3,
          'morphemeIdB': 4,
        });
        await db.insert('morphemeDoublets', {
          'morphemeIdA': 4,
          'morphemeIdB': 3,
        });

        List<int> doubletIds = await dbHelper.getMorphemeDoubletIds(1);

        expect(doubletIds, hasLength(1));
        expect(doubletIds, contains(2));
        expect(doubletIds, isNot(contains(1)));
        expect(doubletIds, isNot(contains(anyOf(3, 4, 5))));
      });
      test('transliterations', () async {
        await db.insert('morphemes', {
          'id': 1,
          'form': 'one',
          'notes': 'english'
        });
        await db.insert('morphemes', {
          'id': 2,
          'form': 'yuan',
          'notes': 'chinese loanword'
        });
        await db.insert('characters', {
          'id': 1,
          'form': '一',
          'notes': 'standard numeral'
        });
        await db.insert('characters', {
          'id': 2,
          'form': '壹',
          'notes': 'financial variant'
        });
        await db.insert('characters', {
          'id': 3,
          'form': '蜀',
          'notes': 'min variant'
        });
        await db.insert('characters', {
          'id': 4,
          'form': '元',
          'notes': 'pronounced like "one"'
        });
        await db.insert('characterMeanings', {
          'morphemeId': 1,
          'characterId': 1,
          'isDefinitive': 1,
        });
        await db.insert('characterMeanings', {
          'morphemeId': 1,
          'characterId': 2,
          'isDefinitive': 0,
        });
        await db.insert('characterMeanings', {
          'morphemeId': 1,
          'characterId': 3,
          'isDefinitive': 0,
        });
        await db.insert('characterMeanings', {
          'morphemeId': 2,
          'characterId': 4,
          'isDefinitive': 1,
        });

        List<int> transliterationIds;

        transliterationIds = await dbHelper.getMorphemeTransliterationIds(1, true);
        expect(transliterationIds, hasLength(1));
        expect(transliterationIds, contains(1));
        expect(transliterationIds, isNot(contains(anyOf(2, 3, 4))));

        transliterationIds = await dbHelper.getMorphemeTransliterationIds(1, false);
        expect(transliterationIds, hasLength(2));
        expect(transliterationIds, containsAll([2, 3]));
        expect(transliterationIds, isNot(contains(anyOf(1, 4))));
      });
      test('products', () async {
        await db.insert('morphemes', {
          'id': 1,
          'form': 'one',
          'notes': 'number'
        });
        await db.insert('morphemes', {
          'id': 2,
          'form': 'two',
          'notes': 'number'
        });
        await db.insert('morphemes', {
          'id': 3,
          'form': 'ly',
          'notes': 'adverb creator'
        });
        await db.insert('morphemes', {
          'id': 4,
          'form': 'ce',
          'notes': 'multiplicative creator'
        });
        await db.insert('words', {
          'id': 1,
          'form': 'only',
          'notes': 'nicki minaj'
        });
        await db.insert('words', {
          'id': 2,
          'form': 'once',
          'notes': 'upon a midnight dreary'
        });
        await db.insert('words', {
          'id': 3,
          'form': 'indubitably',
          'notes': '~'
        });
        await db.insert('wordCompositions', {
          'wordId': 1,
          'morphemeId': 1,
          'position': 0
        });
        await db.insert('wordCompositions', {
          'wordId': 1,
          'morphemeId': 3,
          'position': 1
        });
        await db.insert('wordCompositions', {
          'wordId': 2,
          'morphemeId': 1,
          'position': 0
        });
        await db.insert('wordCompositions', {
          'wordId': 2,
          'morphemeId': 4,
          'position': 1
        });

        List<int> productIds;

        productIds = await dbHelper.getMorphemeProductIds(1);
        expect(productIds, hasLength(2));
        expect(productIds, containsAll([1, 2]));
        expect(productIds, isNot(contains(3)));

        productIds = await dbHelper.getMorphemeProductIds(3);
        expect(productIds, hasLength(1));
        expect(productIds, contains(1));
        expect(productIds, isNot(contains(anyOf(2, 3))));
      });
    });
    group('insertMorpheme()', () {
      test('unconnected', () async {
        
      });
      test('synonyms', () async {
        
      });
      test('doublets', () async {
        
      });
      test('characters', () async {
        
      });
      test('words', () async {
        
      });
    });
    group('updateMorpheme()', () {
      
    });
    group('deleteMorpheme()', () {
      
    });
    group('getMorphemeSynonymIds()', () {
      
    });
    group('insertMorphemeSynonym()', () {
      
    });
    group('deleteMorphemeSynonym()', () {
      
    });
    group('getMorphemeDoubletIds()', () {
      
    });
    group('insertMorphemeDoublet()', () {
      
    });
    group('deleteMorphemeDoublet()', () {
      
    });
  });
  group('word:', () {
    group('getWords()', () {
      
    });
    group('getWordDetails()', () {
      
    });
    group('insertWord()', () {
      
    });
    group('updateWord()', () {
      
    });
    group('deleteWord()', () {
      
    });
    group('getWordSynonymIds()', () {
      
    });
    group('insertWordSynonym()', () {
      
    });
    group('deleteWordSynonym()', () {
      
    });
    group('getWordCalqueIds()', () {
      
    });
    group('insertWordCalque()', () {
      
    });
    group('deleteWordCalque()', () {
      
    });
    group('getWordComponentIds()', () {
      
    });
    group('getMorphemeProductIds()', () {
      
    });
    group('insertWordComposition()', () {
      
    });
    group('deleteWordComposition()', () {
      
    });
  });
  group('character:', () {
    group('getCharacters()', () {
      
    });
    group('getCharacterDetails()', () {
      
    });
    group('insertCharacter()', () {
      
    });
    group('updateCharacter()', () {
      
    });
    group('deleteCharacter()', () {
      
    });
    group('getCharacterMeaningIds()', () {
      
    });
    group('getMorphemeTransliterationIds()', () {
      
    });
    group('insertCharacterMeaning()', () {
      
    });
    group('deleteCharacterMeaning()', () {
      
    });
    group('getCharacterPronunciations()', () {
      
    });
    group('insertCharacterPronunciation()', () {
      
    });
    group('deleteCharacterPronunciation()', () {
      
    });
    group('getCharacterComponents()', () {
      
    });
    group('getCharacterProducts()', () {
      
    });
    group('insertCharacterComposition()', () {
      
    });
    group('deleteCharacterComposition()', () {
      
    });
  });
}