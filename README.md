# ✏️ KidWrite — Flutter Writing Practice App

A writing practice app for children under 6 — pre-writing lines, shapes, numbers and letters
across English, Malayalam, Hindi and Tamil. Free, fully offline, no ads, no in-app purchases,
no analytics, no data collection.

All 51 Malayalam characters have a hand-authored stroke path: the demo hand follows the order
a teacher uses, not a guess made from the font.

## Privacy

KidWrite does not collect any personal data. All progress is stored locally on the device and never transmitted. The app works fully offline and contains no ads or in-app purchases.

🔗 [Privacy Policy](https://kidwrite.atsdigitalservice.co.in/privacy_policy.html) ·
[Press kit](https://kidwrite.atsdigitalservice.co.in)

## Links

- App Store — [KidWrite](https://apps.apple.com/in/app/kidwrite/id6781143198) · `id6781143198`
- Google Play — [KidWrite](https://play.google.com/store/apps/details?id=com.atsIOSDev.kidWrite) · `com.atsIOSDev.kidWrite`
- Site, privacy policy and version feed are served from `docs/` via GitHub Pages

---

## Architecture

```
Clean Architecture + MVVM + BLoC

lib/
├── core/               # Shared utilities
│   ├── constants/      # AppColors, AppConstants, LanguageId
│   ├── router/         # GoRouter navigation
│   ├── theme/          # AppTheme (Material 3)
│   ├── utils/          # ResponsiveHelper (phone/tablet)
│   └── widgets/        # AnimatedBackground
│
├── domain/             # Business logic (no Flutter deps)
│   ├── entities/       # Character, Language, Progress
│   ├── repositories/   # Abstract contracts
│   └── usecases/       # GetCharacters, GetLanguages, GetProgress, SaveProgress
│
├── data/               # Data layer
│   ├── datasources/    # CharacterLocalDataSource, ProgressLocalDataSource
│   ├── models/         # CharacterModel, ProgressModel (JSON serialize)
│   └── repositories/   # Implementations wiring datasource → domain
│
├── presentation/       # UI layer
│   ├── blocs/          # HomeBloc, WritingBloc, ProgressBloc, MusicBloc
│   ├── pages/          # SplashPage, HomePage, CharacterListPage, WritingPracticePage
│   └── widgets/        # DrawingCanvas, LanguageCard, CharacterGridCard, ...
│
├── injection_container.dart   # GetIt DI wiring
└── main.dart
```

## Setup

1. **Install Flutter** (≥ 3.0): https://flutter.dev/docs/get-started/install

2. **Add audio assets** (optional — app works silently without them):
   ```
   assets/audio/bg_music.mp3    # Looping background music
   assets/audio/success.mp3     # Played on successful trace
   assets/audio/tap.mp3         # Button tap sound
   assets/audio/clear.mp3       # Canvas clear sound
   ```

3. **Add font files** (for non-Latin scripts):
   Download from Google Fonts and place in `assets/fonts/`:
    - `NotoSansMalayalam-Regular.ttf`
    - `NotoSansDevanagari-Regular.ttf`
    - `NotoSansTamil-Regular.ttf`

4. **Get dependencies & run**:
   ```bash
   flutter pub get
   flutter run
   ```

## Key features

- Six sets: pre-writing lines, shapes, numbers (0–9), English capitals and small letters,
  Malayalam, Hindi (Devanagari), Tamil
- **Guided stroke paths** for lines, shapes, numbers, English and all 51 Malayalam characters —
  a demo hand and dotted trail follow the real stroke order, checked stroke by stroke.
  Hindi and Tamil free-trace over the bundled glyph
- **Three stars per character.** Two guided attempts, then the third removes the hand and the
  dots entirely and the child writes from memory, in any stroke order. Three stars unlock the
  next character on the level map
- **Picture-word reward** on every success — "A for Apple", "അ, അമ്മ" — spoken aloud, with the
  number sets showing the quantity so it can be counted by eye
- Per-character progress with stars, persisted via SharedPreferences
- Confetti celebration, looping background music with a mute toggle
- Animated floating-bubble background with per-language colour themes
- Responsive layouts for phones and tablets/iPads
- Clean Architecture + MVVM + BLoC throughout (GetIt DI)

## Generated assets

Two scripts produce the audio the app prefers over live text-to-speech. Both need
`pip install gtts` and an internet connection, and both skip files that already exist:

```bash
python3 scripts/generate_pronunciations.py   # assets/audio/letters/ — the letter sounds
python3 scripts/generate_word_audio.py       # assets/audio/words/   — the reward words
```

`generate_word_audio.py` reads the words from `lib/Core/data/letter_words.dart` and the ids from
the character table, so it stays correct when either is edited. `--force` overwrites, `--slow`
uses a more deliberate voice. Without these files the app falls back to the device voice, which
matters most for Malayalam — iOS has no Malayalam voice at all.

Optional artwork: drop a PNG at `assets/words/<character id>.png` and it replaces the emoji on
the reward card for that letter. See the README in that folder for the id scheme.

## Build notes

**Android** — if you see `launch_background not found`, ensure these files exist:
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/values/styles.xml`

**iOS** — if `flutter_tts` causes a Swift Package Manager error:
```bash
flutter config --no-enable-swift-package-manager
flutter clean && flutter pub get
cd ios && pod install && cd ..
```

## License

© 2026 Athul Sethumadhavan. All rights reserved.