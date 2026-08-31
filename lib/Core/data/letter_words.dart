import '../../domain/entities/character.dart';

/// The picture-word shown when a child finishes a letter — "A for Apple",
/// "അ … അമ്മ".
///
/// [emoji] is the picture that always works: no files, no licensing, no
/// download, and it scales to any screen. If real artwork is dropped in at
/// `assets/words/<character.id>.png` the card uses that instead, so the set
/// can be replaced one letter at a time without touching this table.
class LetterWord {
  /// The word in its own script — 'Apple', 'അമ്മ'.
  final String word;

  /// Roman spelling for non-Latin scripts. Null for English and numbers,
  /// where the word already reads as itself.
  final String? roman;

  /// Fallback picture.
  final String emoji;

  /// What the app says out loud.
  final String spoken;

  const LetterWord({
    required this.word,
    required this.emoji,
    required this.spoken,
    this.roman,
  });
}

class LetterWords {
  const LetterWords._();

  /// File-safe name for this character's optional artwork and voice clip.
  ///
  /// The raw ids can't be used as filenames: capital and small English share
  /// the `en_lower_` prefix and differ only in the letter's case, so
  /// `en_lower_A` and `en_lower_a` are the *same file* on macOS and Windows —
  /// one silently overwrites the other. Capitals get their own prefix.
  static String fileStem(Character c) =>
      c.languageId == 'english_upper' ? 'en_upper_${c.symbol}' : c.id;

  /// Artwork that overrides [LetterWord.emoji] when the file exists.
  static String assetFor(Character c) => 'assets/words/${fileStem(c)}.png';

  /// Null for scripts with no word list (shapes, lines, Hindi, Tamil) — the
  /// caller then keeps the plain celebration.
  static LetterWord? of(Character c) {
    switch (c.languageId) {
      case 'english_upper':
        return _upper[c.symbol];
      case 'english_lower':
        return _lower[c.symbol];
      case 'numbers':
        return _numbers[c.symbol];
      case 'malayalam':
        return _malayalam[c.symbol];
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // English
  // ---------------------------------------------------------------------------

  /// word + emoji, shared by both cases; the two maps below only differ in
  /// how the word and the spoken line are cased.
  static const List<List<String>> _english = [
    ['A', 'Apple', '🍎'],
    ['B', 'Ball', '⚽'],
    ['C', 'Cat', '🐱'],
    ['D', 'Dog', '🐶'],
    ['E', 'Elephant', '🐘'],
    ['F', 'Fish', '🐟'],
    ['G', 'Grapes', '🍇'],
    ['H', 'Hat', '🎩'],
    ['I', 'Ice cream', '🍦'],
    ['J', 'Juice', '🧃'],
    ['K', 'Kite', '🪁'],
    ['L', 'Lion', '🦁'],
    ['M', 'Moon', '🌙'],
    ['N', 'Nest', '🪺'],
    ['O', 'Orange', '🍊'],
    ['P', 'Pencil', '✏️'],
    ['Q', 'Queen', '👑'],
    ['R', 'Rainbow', '🌈'],
    ['S', 'Sun', '☀️'],
    ['T', 'Tree', '🌳'],
    ['U', 'Umbrella', '☂️'],
    ['V', 'Van', '🚐'],
    ['W', 'Watch', '⌚'],
    ['X', 'Xylophone', '🎹'],
    ['Y', 'Yo-yo', '🪀'],
    ['Z', 'Zebra', '🦓'],
  ];

  static final Map<String, LetterWord> _upper = {
    for (final e in _english)
      e[0]: LetterWord(word: e[1], emoji: e[2], spoken: '${e[0]} for ${e[1]}'),
  };

  static final Map<String, LetterWord> _lower = {
    for (final e in _english)
      e[0].toLowerCase(): LetterWord(
        word: e[1].toLowerCase(),
        emoji: e[2],
        spoken: '${e[0].toLowerCase()} for ${e[1].toLowerCase()}',
      ),
  };

  // ---------------------------------------------------------------------------
  // Numbers — the picture *is* the count, so the child can check it by eye.
  // A different thing each time, so counting is the point rather than the
  // apple: "one cat", "two apples", "eight snails".
  // ---------------------------------------------------------------------------

  /// number word, what is being counted (already plural where it should be),
  /// one of the things.
  static const List<List<String>> _numberItems = [
    ['zero', '', '🧺'], // an empty basket — nothing to count
    ['one', 'cat', '🐱'],
    ['two', 'apples', '🍎'],
    ['three', 'balloons', '🎈'],
    ['four', 'fish', '🐟'],
    ['five', 'oranges', '🍊'],
    ['six', 'flowers', '🌸'],
    ['seven', 'stars', '⭐'],
    ['eight', 'snails', '🐌'],
    ['nine', 'leaves', '🍃'],
  ];

  static final Map<String, LetterWord> _numbers = {
    for (int n = 0; n <= 9; n++)
      '$n': LetterWord(
        word: _numberItems[n][1].isEmpty
            ? _numberItems[n][0]
            : '${_numberItems[n][0]} ${_numberItems[n][1]}',
        emoji: _numberItems[n][2] * (n == 0 ? 1 : n),
        spoken: _numberItems[n][1].isEmpty
            ? _numberItems[n][0]
            : '${_numberItems[n][0]} ${_numberItems[n][1]}',
      ),
  };

  // ---------------------------------------------------------------------------
  // Malayalam
  //
  // Most entries start with their letter. The rare ones — ങ ഠ ഢ ഝ ണ ള ഴ and
  // the two sign characters അം അഃ — practically never begin a word, so they
  // use a familiar word that *contains* the letter instead. That is how
  // Malayalam charts teach them too.
  // ---------------------------------------------------------------------------

  static const List<List<String>> _ml = [
    // symbol, word, roman, emoji
    ['അ', 'അമ്മ', 'amma', '👩'],
    ['ആ', 'ആന', 'aana', '🐘'],
    ['ഇ', 'ഇല', 'ila', '🍃'],
    ['ഈ', 'ഈച്ച', 'eecha', '🪰'],
    ['ഉ', 'ഉടുപ്പ്', 'uduppu', '👗'],
    ['ഊ', 'ഊഞ്ഞാൽ', 'oonjaal', '🛝'],
    ['ഋ', 'ഋഷി', 'rishi', '🧘'],
    ['എ', 'എലി', 'eli', '🐭'],
    ['ഏ', 'ഏണി', 'eni', '🪜'],
    ['ഐ', 'ഐസ്', 'ice', '🧊'],
    ['ഒ', 'ഒട്ടകം', 'ottakam', '🐪'],
    ['ഓ', 'ഓണം', 'onam', '🎉'],
    ['ഔ', 'ഔഷധം', 'aushadham', '💊'],
    ['അം', 'മാമ്പഴം', 'maampazham', '🥭'],
    ['അഃ', 'ദുഃഖം', 'duhkham', '😢'],
    ['ക', 'കപ്പൽ', 'kappal', '🚢'],
    ['ഖ', 'ഖഡ്ഗം', 'khadgam', '🗡️'],
    ['ഗ', 'ഗരുഡൻ', 'garudan', '🦅'],
    ['ഘ', 'ഘടികാരം', 'ghadikaaram', '🕰️'],
    ['ങ', 'തേങ്ങ', 'thenga', '🥥'],
    ['ച', 'ചന്ദ്രൻ', 'chandran', '🌙'],
    ['ഛ', 'ഛത്രം', 'chathram', '☂️'],
    ['ജ', 'ജനൽ', 'janal', '🪟'],
    ['ഝ', 'ഝരി', 'jhari', '💧'],
    ['ഞ', 'ഞണ്ട്', 'njandu', '🦀'],
    ['ട', 'ടയർ', 'tyre', '🛞'],
    ['ഠ', 'പഠനം', 'padanam', '📖'],
    ['ഡ', 'ഡോക്ടർ', 'doctor', '👨‍⚕️'],
    ['ഢ', 'ഢക്ക', 'dhakka', '🥁'],
    ['ണ', 'വീണ', 'veena', '🎻'],
    ['ത', 'തത്ത', 'thatha', '🦜'],
    ['ഥ', 'രഥം', 'ratham', '🎠'],
    ['ദ', 'ദന്തം', 'dantham', '🦷'],
    ['ധ', 'ധനു', 'dhanu', '🏹'],
    ['ന', 'നക്ഷത്രം', 'nakshathram', '⭐'],
    ['പ', 'പശു', 'pashu', '🐄'],
    ['ഫ', 'ഫലം', 'phalam', '🍇'],
    ['ബ', 'ബസ്', 'bus', '🚌'],
    ['ഭ', 'ഭൂമി', 'bhoomi', '🌍'],
    ['മ', 'മയിൽ', 'mayil', '🦚'],
    ['യ', 'യന്ത്രം', 'yanthram', '⚙️'],
    ['ര', 'രാജാവ്', 'raajaavu', '🤴'],
    ['റ', 'റോസ്', 'rose', '🌹'],
    ['ല', 'ലഡ്ഡു', 'laddu', '🍬'],
    ['ള', 'കുളം', 'kulam', '🏞️'],
    ['ഴ', 'വാഴ', 'vaazha', '🍌'],
    ['വ', 'വള്ളം', 'vallam', '🛶'],
    ['ശ', 'ശലഭം', 'shalabham', '🦋'],
    ['ഷ', 'ഷർട്ട്', 'shirt', '👕'],
    ['സ', 'സൂര്യൻ', 'sooryan', '☀️'],
    ['ഹ', 'ഹംസം', 'hamsam', '🦢'],
  ];

  static final Map<String, LetterWord> _malayalam = {
    for (final e in _ml)
      e[0]: LetterWord(
        word: e[1],
        roman: e[2],
        emoji: e[3],
        // Letter first, then the word — "അ അമ്മ", the way it is taught. The
        // comma is a pause: without it a bare vowel runs straight into the
        // word and the two blur together.
        spoken: '${e[0]}, ${e[1]}',
      ),
  };

  /// What to read out when the device has no voice for the script — iOS has
  /// no Malayalam one at all. Mirrors [LetterWord.spoken] in roman letters:
  /// the letter's sound, then the word. "a amma", "aa aana".
  static String? romanSpoken(Character c, LetterWord w) =>
      w.roman == null ? null : '${c.pronunciation} ${w.roman}';
}
