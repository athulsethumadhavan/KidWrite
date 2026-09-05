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

  /// Null for scripts with no word list (shapes, lines) — the caller then
  /// keeps the plain celebration.
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
      case 'hindi':
        return _hindi[c.symbol];
      case 'tamil':
        return _tamil[c.symbol];
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

  // ---------------------------------------------------------------------------
  // Hindi — the words every Devanagari primer uses, so a parent recognises
  // them. All thirteen vowels and all thirty-three consonants.
  //
  // Some have no emoji that really means the thing — marked below. They read
  // as near-misses rather than nonsense, and drop out the moment artwork
  // lands in assets/words/hi_<vowel|cons>_<n>.png.
  //
  // ङ and ञ never begin a Hindi word, so like the rare Malayalam letters they
  // use a familiar word that *contains* them. Both are written here in the
  // conjunct form the letter actually appears in — रङ्ग, पञ्च — where modern
  // spelling would use the anusvara (रंग, पंच). The conjunct is the point:
  // the child has to be able to see the letter in the word.
  // ---------------------------------------------------------------------------
  static const List<List<String>> _hi = [
    // symbol, word, roman, emoji
    ['अ', 'अनार', 'anaar', '🍒'], // pomegranate — no emoji exists
    ['आ', 'आम', 'aam', '🥭'],
    ['इ', 'इमली', 'imli', '🫘'], // tamarind — nearest pod
    ['ई', 'ईख', 'eekh', '🎋'], // sugarcane — nearest tall cane
    ['उ', 'उल्लू', 'ullu', '🦉'],
    ['ऊ', 'ऊन', 'oon', '🧶'],
    ['ऋ', 'ऋषि', 'rishi', '🧙'], // sage — 🧘 read as yoga, not a person
    ['ए', 'एकतारा', 'ektaara', '🪕'], // ektara — nearest string instrument
    ['ऐ', 'ऐनक', 'ainak', '👓'],
    ['ओ', 'ओखली', 'okhli', '🥣'], // mortar — nearest bowl
    ['औ', 'औरत', 'aurat', '👩'],
    ['अं', 'अंगूर', 'angoor', '🍇'],
    ['अः', 'नमः', 'namah', '🙏'],
    ['क', 'कबूतर', 'kabootar', '🕊️'],
    ['ख', 'खरगोश', 'khargosh', '🐰'],
    ['ग', 'गाय', 'gaay', '🐄'],
    ['घ', 'घड़ी', 'ghadi', '⌚'],
    ['ङ', 'रङ्ग', 'rang', '🎨'],
    ['च', 'चम्मच', 'chammach', '🥄'],
    ['छ', 'छाता', 'chhata', '☂️'],
    ['ज', 'जहाज़', 'jahaaz', '🚢'],
    ['झ', 'झंडा', 'jhanda', '🚩'],
    ['ञ', 'पञ्च', 'panch', '🖐️'],
    ['ट', 'टमाटर', 'tamatar', '🍅'],
    ['ठ', 'ठेला', 'thela', '🛒'], // handcart — nearest trolley
    ['ड', 'डमरू', 'damroo', '🪘'],
    ['ढ', 'ढोल', 'dhol', '🥁'],
    ['ण', 'वीणा', 'veena', '🎻'], // veena — nearest string instrument
    ['त', 'तितली', 'titli', '🦋'],
    ['थ', 'थाली', 'thaali', '🍽️'],
    ['द', 'दरवाज़ा', 'darwaaza', '🚪'],
    ['ध', 'धनुष', 'dhanush', '🏹'],
    ['न', 'नल', 'nal', '🚰'],
    ['प', 'पतंग', 'patang', '🪁'],
    ['फ', 'फल', 'phal', '🍎'],
    ['ब', 'बतख़', 'batakh', '🦆'],
    ['भ', 'भालू', 'bhaaloo', '🐻'],
    ['म', 'मछली', 'machhli', '🐟'],
    ['य', 'यान', 'yaan', '🚀'],
    ['र', 'रथ', 'rath', '🎠'], // chariot — nearest horse-drawn ride
    ['ल', 'लोमड़ी', 'lomdi', '🦊'],
    ['व', 'वन', 'van', '🌲'],
    ['श', 'शेर', 'sher', '🦁'],
    ['ष', 'पुष्प', 'pushp', '🌸'],
    ['स', 'सूरज', 'sooraj', '☀️'],
    ['ह', 'हाथी', 'haathi', '🐘'],
  ];

  static final Map<String, LetterWord> _hindi = {
    for (final e in _hi)
      e[0]: LetterWord(
        word: e[1],
        roman: e[2],
        emoji: e[3],
        spoken: '${e[0]}, ${e[1]}',
      ),
  };

  // ---------------------------------------------------------------------------
  // Tamil — the words a Tamil primer uses, so a parent recognises them.
  //
  // Ten of the consonants never begin a Tamil word: ங ஞ ட ண ல ழ ள ற ன, and
  // the grantha ஸ. Like the rare Malayalam and Hindi letters they use a
  // familiar word that *contains* them instead, which is how Tamil charts
  // teach them too — தங்கம் for ங, கிளி for ள, மான் for ன.
  // ---------------------------------------------------------------------------
  static const List<List<String>> _ta = [
    // symbol, word, roman, emoji
    ['அ', 'அம்மா', 'ammaa', '👩'],
    ['ஆ', 'ஆடு', 'aadu', '🐐'],
    ['இ', 'இலை', 'ilai', '🍃'],
    ['ஈ', 'ஈ', 'ee', '🪰'],
    ['உ', 'உரல்', 'ural', '🥣'], // grinding mortar — nearest bowl
    ['ஊ', 'ஊஞ்சல்', 'oonjal', '🛝'],
    ['எ', 'எலி', 'eli', '🐭'],
    ['ஏ', 'ஏணி', 'eni', '🪜'],
    ['ஐ', 'ஐஸ்', 'ice', '🧊'],
    ['ஒ', 'ஒட்டகம்', 'ottagam', '🐪'],
    ['ஓ', 'ஓடம்', 'odam', '🛶'],
    ['ஔ', 'ஔடதம்', 'audatham', '💊'],
    ['க', 'காகம்', 'kaagam', '🐦'],
    ['ங', 'தங்கம்', 'thangam', '🥇'],
    ['ச', 'சங்கு', 'sangu', '🐚'],
    ['ஞ', 'ஞாயிறு', 'nyaayiru', '☀️'],
    ['ட', 'கட்டில்', 'kattil', '🛏️'],
    ['ண', 'கண்', 'kan', '👁️'],
    ['த', 'தேன்', 'then', '🍯'],
    ['ந', 'நரி', 'nari', '🦊'],
    ['ப', 'பசு', 'pasu', '🐄'],
    ['ம', 'மயில்', 'mayil', '🦚'],
    ['ய', 'யானை', 'yaanai', '🐘'],
    ['ர', 'ரயில்', 'rayil', '🚂'],
    ['ல', 'மலர்', 'malar', '🌸'],
    ['வ', 'வண்டி', 'vandi', '🛒'], // bullock cart — nearest cart
    ['ழ', 'மழை', 'mazhai', '🌧️'],
    ['ள', 'கிளி', 'kili', '🦜'],
    ['ற', 'ஆறு', 'aaru', '🏞️'],
    ['ன', 'மான்', 'maan', '🦌'],
    ['ஜ', 'ஜன்னல்', 'jannal', '🪟'],
    ['ஷ', 'ஷூ', 'shoe', '👟'],
    ['ஸ', 'பஸ்', 'bus', '🚌'],
    ['ஹ', 'ஹெலிகாப்டர்', 'helicopter', '🚁'],
  ];

  static final Map<String, LetterWord> _tamil = {
    for (final e in _ta)
      e[0]: LetterWord(
        word: e[1],
        roman: e[2],
        emoji: e[3],
        spoken: '${e[0]}, ${e[1]}',
      ),
  };

  /// What to read out when the device has no voice for the script — iOS has
  /// no Malayalam one at all. Mirrors [LetterWord.spoken] in roman letters:
  /// the letter's sound, then the word. "a amma", "aa aana".
  static String? romanSpoken(Character c, LetterWord w) =>
      w.roman == null ? null : '${c.pronunciation} ${w.roman}';
}
