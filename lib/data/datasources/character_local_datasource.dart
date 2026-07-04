import '../../Core/Constants/app_constants.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/language.dart';
import '../models/character_model.dart';

abstract class CharacterLocalDataSource {
  List<Language> getLanguages();
  List<CharacterModel> getCharacters(String languageId);
}

class CharacterLocalDataSourceImpl implements CharacterLocalDataSource {
  // ---------------------------------------------------------------------------
  // Languages
  // ---------------------------------------------------------------------------
  @override
  List<Language> getLanguages() => [
    const Language(
      id: LanguageId.english,
      displayName: 'English',
      nativeName: 'English',
      emoji: '🇬🇧',
      fontFamily: 'Nunito',
    ),
    const Language(
      id: LanguageId.numbers,
      displayName: 'Numbers',
      nativeName: '123',
      emoji: '🔢',
      fontFamily: 'Nunito',
    ),
    const Language(
      id: LanguageId.malayalam,
      displayName: 'Malayalam',
      nativeName: 'മലയാളം',
      emoji: '🇮🇳',
      fontFamily: 'NotoSansMalayalam',
    ),
    const Language(
      id: LanguageId.hindi,
      displayName: 'Hindi',
      nativeName: 'हिन्दी',
      emoji: '🇮🇳',
      fontFamily: 'NotoSansDevanagari',
    ),
    const Language(
      id: LanguageId.tamil,
      displayName: 'Tamil',
      nativeName: 'தமிழ்',
      emoji: '🇮🇳',
      fontFamily: 'NotoSansTamil',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Characters
  // ---------------------------------------------------------------------------
  @override
  List<CharacterModel> getCharacters(String languageId) {
    switch (languageId) {
      case LanguageId.english:
        return _englishCharacters();
      case LanguageId.numbers:
        return _numberCharacters();
      case LanguageId.malayalam:
        return _malayalamCharacters();
      case LanguageId.hindi:
        return _hindiCharacters();
      case LanguageId.tamil:
        return _tamilCharacters();
      default:
        return [];
    }
  }

  // ---------------------------------------------------------------------------
  // English A-Z (uppercase) + a-z (lowercase)
  // ---------------------------------------------------------------------------
  List<CharacterModel> _englishCharacters() {
    final uppercaseData = [
      ['A', 'Letter A', 'ey'],  ['B', 'Letter B', 'bee'],
      ['C', 'Letter C', 'see'], ['D', 'Letter D', 'dee'],
      ['E', 'Letter E', 'ee'],  ['F', 'Letter F', 'ef'],
      ['G', 'Letter G', 'jee'], ['H', 'Letter H', 'aych'],
      ['I', 'Letter I', 'eye'], ['J', 'Letter J', 'jay'],
      ['K', 'Letter K', 'kay'], ['L', 'Letter L', 'el'],
      ['M', 'Letter M', 'em'],  ['N', 'Letter N', 'en'],
      ['O', 'Letter O', 'oh'],  ['P', 'Letter P', 'pee'],
      ['Q', 'Letter Q', 'cue'], ['R', 'Letter R', 'ar'],
      ['S', 'Letter S', 'ess'], ['T', 'Letter T', 'tee'],
      ['U', 'Letter U', 'you'], ['V', 'Letter V', 'vee'],
      ['W', 'Letter W', 'double-you'], ['X', 'Letter X', 'ex'],
      ['Y', 'Letter Y', 'why'], ['Z', 'Letter Z', 'zee'],
    ];
    final lowercaseData = [
      ['a', 'Small a', 'ey'],  ['b', 'Small b', 'bee'],
      ['c', 'Small c', 'see'], ['d', 'Small d', 'dee'],
      ['e', 'Small e', 'ee'],  ['f', 'Small f', 'ef'],
      ['g', 'Small g', 'jee'], ['h', 'Small h', 'aych'],
      ['i', 'Small i', 'eye'], ['j', 'Small j', 'jay'],
      ['k', 'Small k', 'kay'], ['l', 'Small l', 'el'],
      ['m', 'Small m', 'em'],  ['n', 'Small n', 'en'],
      ['o', 'Small o', 'oh'],  ['p', 'Small p', 'pee'],
      ['q', 'Small q', 'cue'], ['r', 'Small r', 'ar'],
      ['s', 'Small s', 'ess'], ['t', 'Small t', 'tee'],
      ['u', 'Small u', 'you'], ['v', 'Small v', 'vee'],
      ['w', 'Small w', 'double-you'], ['x', 'Small x', 'ex'],
      ['y', 'Small y', 'why'], ['z', 'Small z', 'zee'],
    ];

    final List<CharacterModel> result = [];
    for (int i = 0; i < uppercaseData.length; i++) {
      result.add(CharacterModel(
        id: 'en_lower_${uppercaseData[i][0]}',
        symbol: uppercaseData[i][0],
        name: uppercaseData[i][1],
        pronunciation: uppercaseData[i][2],
        languageId: LanguageId.english,
        category: CharacterCategory.uppercase,
        orderIndex: i,
      ));
    }
    for (int i = 0; i < lowercaseData.length; i++) {
      result.add(CharacterModel(
        id: 'en_lower_${lowercaseData[i][0]}',
        symbol: lowercaseData[i][0],
        name: lowercaseData[i][1],
        pronunciation: lowercaseData[i][2],
        languageId: LanguageId.english,
        category: CharacterCategory.lowercase,
        orderIndex: 26 + i,
      ));
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Numbers 0-9
  // ---------------------------------------------------------------------------
  List<CharacterModel> _numberCharacters() {
    final data = [
      ['0', 'Zero', 'zero'],   ['1', 'One', 'one'],
      ['2', 'Two', 'two'],     ['3', 'Three', 'three'],
      ['4', 'Four', 'four'],   ['5', 'Five', 'five'],
      ['6', 'Six', 'six'],     ['7', 'Seven', 'seven'],
      ['8', 'Eight', 'eight'], ['9', 'Nine', 'nine'],
    ];
    return List.generate(
      data.length,
          (i) => CharacterModel(
        id: 'num_${data[i][0]}',
        symbol: data[i][0],
        name: data[i][1],
        pronunciation: data[i][2],
        languageId: LanguageId.numbers,
        category: CharacterCategory.number,
        orderIndex: i,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Malayalam vowels (swarams) + selected consonants (vyanjanams)
  // ---------------------------------------------------------------------------
  List<CharacterModel> _malayalamCharacters() {
    final vowels = [
      ['അ', 'A', 'a'],  ['ആ', 'Aa', 'aa'], ['ഇ', 'I', 'i'],
      ['ഈ', 'Ii', 'ii'],['ഉ', 'U', 'u'],   ['ഊ', 'Uu', 'uu'],
      ['എ', 'E', 'e'],  ['ഏ', 'Ee', 'ee'], ['ഐ', 'Ai', 'ai'],
      ['ഒ', 'O', 'o'],  ['ഓ', 'Oo', 'oo'], ['ഔ', 'Au', 'au'],
    ];
    final consonants = [
      ['ക', 'Ka', 'ka'],  ['ഖ', 'Kha', 'kha'], ['ഗ', 'Ga', 'ga'],
      ['ഘ', 'Gha', 'gha'],['ങ', 'Nga', 'nga'],
      ['ച', 'Cha', 'cha'],['ഛ', 'Chha', 'chha'],['ജ', 'Ja', 'ja'],
      ['ഝ', 'Jha', 'jha'],['ഞ', 'Nya', 'nya'],
      ['ട', 'Ta', 'ta'],  ['ഠ', 'Tha', 'tha'], ['ഡ', 'Da', 'da'],
      ['ഢ', 'Dha', 'dha'],['ണ', 'Na', 'na'],
      ['ത', 'Tha', 'tha'],['ഥ', 'Thha', 'thha'],['ദ', 'Da', 'da'],
      ['ധ', 'Dha', 'dha'],['ന', 'Na', 'na'],
      ['പ', 'Pa', 'pa'],  ['ഫ', 'Pha', 'pha'], ['ബ', 'Ba', 'ba'],
      ['ഭ', 'Bha', 'bha'],['മ', 'Ma', 'ma'],
      ['യ', 'Ya', 'ya'],  ['ര', 'Ra', 'ra'],   ['ല', 'La', 'la'],
      ['വ', 'Va', 'va'],  ['ശ', 'Sha', 'sha'],  ['ഷ', 'Sha', 'sha'],
      ['സ', 'Sa', 'sa'],  ['ഹ', 'Ha', 'ha'],   ['ള', 'La', 'la'],
      ['ഴ', 'Zha', 'zha'],['റ', 'Ra', 'ra'],
    ];

    final List<CharacterModel> result = [];
    for (int i = 0; i < vowels.length; i++) {
      result.add(CharacterModel(
        id: 'ml_vowel_$i',
        symbol: vowels[i][0],
        name: vowels[i][1],
        pronunciation: vowels[i][2],
        languageId: LanguageId.malayalam,
        category: CharacterCategory.vowel,
        orderIndex: i,
      ));
    }
    for (int i = 0; i < consonants.length; i++) {
      result.add(CharacterModel(
        id: 'ml_cons_$i',
        symbol: consonants[i][0],
        name: consonants[i][1],
        pronunciation: consonants[i][2],
        languageId: LanguageId.malayalam,
        category: CharacterCategory.consonant,
        orderIndex: vowels.length + i,
      ));
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Hindi (Devanagari) vowels + consonants
  // ---------------------------------------------------------------------------
  List<CharacterModel> _hindiCharacters() {
    final vowels = [
      ['अ', 'A', 'a'],  ['आ', 'Aa', 'aa'], ['इ', 'I', 'i'],
      ['ई', 'Ii', 'ii'],['उ', 'U', 'u'],   ['ऊ', 'Uu', 'uu'],
      ['ए', 'E', 'e'],  ['ऐ', 'Ai', 'ai'], ['ओ', 'O', 'o'],
      ['औ', 'Au', 'au'],
    ];
    final consonants = [
      ['क', 'Ka', 'ka'],  ['ख', 'Kha', 'kha'],['ग', 'Ga', 'ga'],
      ['घ', 'Gha', 'gha'],['ङ', 'Nga', 'nga'],
      ['च', 'Cha', 'cha'],['छ', 'Chha', 'chha'],['ज', 'Ja', 'ja'],
      ['झ', 'Jha', 'jha'],['ञ', 'Nya', 'nya'],
      ['ट', 'Ta', 'ta'],  ['ठ', 'Tha', 'tha'],['ड', 'Da', 'da'],
      ['ढ', 'Dha', 'dha'],['ण', 'Na', 'na'],
      ['त', 'Ta', 'ta'],  ['थ', 'Tha', 'tha'],['द', 'Da', 'da'],
      ['ध', 'Dha', 'dha'],['न', 'Na', 'na'],
      ['प', 'Pa', 'pa'],  ['फ', 'Pha', 'pha'],['ब', 'Ba', 'ba'],
      ['भ', 'Bha', 'bha'],['म', 'Ma', 'ma'],
      ['य', 'Ya', 'ya'],  ['र', 'Ra', 'ra'],  ['ल', 'La', 'la'],
      ['व', 'Va', 'va'],  ['श', 'Sha', 'sha'],['ष', 'Sha', 'sha'],
      ['स', 'Sa', 'sa'],  ['ह', 'Ha', 'ha'],
    ];

    final List<CharacterModel> result = [];
    for (int i = 0; i < vowels.length; i++) {
      result.add(CharacterModel(
        id: 'hi_vowel_$i',
        symbol: vowels[i][0],
        name: vowels[i][1],
        pronunciation: vowels[i][2],
        languageId: LanguageId.hindi,
        category: CharacterCategory.vowel,
        orderIndex: i,
      ));
    }
    for (int i = 0; i < consonants.length; i++) {
      result.add(CharacterModel(
        id: 'hi_cons_$i',
        symbol: consonants[i][0],
        name: consonants[i][1],
        pronunciation: consonants[i][2],
        languageId: LanguageId.hindi,
        category: CharacterCategory.consonant,
        orderIndex: vowels.length + i,
      ));
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Tamil vowels (uyir) + consonants (mey)
  // ---------------------------------------------------------------------------
  List<CharacterModel> _tamilCharacters() {
    final vowels = [
      ['அ', 'A', 'a'],  ['ஆ', 'Aa', 'aa'], ['இ', 'I', 'i'],
      ['ஈ', 'Ii', 'ii'],['உ', 'U', 'u'],   ['ஊ', 'Uu', 'uu'],
      ['எ', 'E', 'e'],  ['ஏ', 'Ee', 'ee'], ['ஐ', 'Ai', 'ai'],
      ['ஒ', 'O', 'o'],  ['ஓ', 'Oo', 'oo'], ['ஔ', 'Au', 'au'],
    ];
    final consonants = [
      ['க', 'Ka', 'ka'],  ['ங', 'Nga', 'nga'],
      ['ச', 'Cha', 'cha'],['ஞ', 'Nya', 'nya'],
      ['ட', 'Ta', 'ta'],  ['ண', 'Na', 'na'],
      ['த', 'Tha', 'tha'],['ந', 'Na', 'na'],
      ['ப', 'Pa', 'pa'],  ['ம', 'Ma', 'ma'],
      ['ய', 'Ya', 'ya'],  ['ர', 'Ra', 'ra'],
      ['ல', 'La', 'la'],  ['வ', 'Va', 'va'],
      ['ழ', 'Zha', 'zha'],['ள', 'La', 'la'],
      ['ற', 'Ra', 'ra'],  ['ன', 'Na', 'na'],
      ['ஜ', 'Ja', 'ja'],  ['ஷ', 'Sha', 'sha'],
      ['ஸ', 'Sa', 'sa'],  ['ஹ', 'Ha', 'ha'],
    ];

    final List<CharacterModel> result = [];
    for (int i = 0; i < vowels.length; i++) {
      result.add(CharacterModel(
        id: 'ta_vowel_$i',
        symbol: vowels[i][0],
        name: vowels[i][1],
        pronunciation: vowels[i][2],
        languageId: LanguageId.tamil,
        category: CharacterCategory.vowel,
        orderIndex: i,
      ));
    }
    for (int i = 0; i < consonants.length; i++) {
      result.add(CharacterModel(
        id: 'ta_cons_$i',
        symbol: consonants[i][0],
        name: consonants[i][1],
        pronunciation: consonants[i][2],
        languageId: LanguageId.tamil,
        category: CharacterCategory.consonant,
        orderIndex: vowels.length + i,
      ));
    }
    return result;
  }
}
