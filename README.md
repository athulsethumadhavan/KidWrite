# ✏️ KidWrite

A handwriting app for children under 6. It teaches pre-writing lines, then
shapes, then numbers and letters — the order a teacher uses — across English,
Malayalam, Hindi and Tamil.

Free, fully offline, no ads, no in-app purchases, no analytics, no data
collection. Progress lives on the device and is never transmitted.

- App Store `id6781143198` · Play `com.atsIOSDev.kidWrite`
- [kidwrite.atsdigitalservice.co.in](https://kidwrite.atsdigitalservice.co.in) ·
  [Privacy policy](https://kidwrite.atsdigitalservice.co.in/privacy_policy.html)

---

## What a child works through

| Section | Count | Guided |
|---|---|---|
| Lines | 11 | ✅ |
| Shapes | 9 | ✅ |
| Capital + small letters | 52 | ✅ |
| Numbers | 10 | ✅ |
| Malayalam | 51 (15 vowels, 36 consonants) | ✅ |
| Hindi | 46 (13 vowels, 33 consonants) | ✅ |
| Tamil | 34 (12 vowels, 22 consonants) | ✅ |

**Guided** means the app knows the real stroke order: a cartoon hand
demonstrates each stroke, a dotted trail shows where to go, and each stroke is
checked on its own. Every character in every script is guided — nothing falls
back to tracing over the bundled glyph.

## How a letter is learned

Three stars per character. The first two attempts are guided; **the third
removes the hand and the dotted path entirely** and the child writes from
memory in any stroke order. That last step is the app's main differentiator —
most tracing apps stop at the dotted line.

Three stars unlock the next character on the level map.

## Architecture

BLoC + GetIt + go_router.

```
lib/
├── Core/
│   ├── Constants/      app_colors, app_constants (every tunable lives here)
│   ├── data/           letter_words.dart — the "A for Apple" reward table
│   ├── tracing/        letter_strokes.dart      Latin, shapes, lines
│   │                   malayalam_strokes.dart   51 Malayalam paths
│   │                   hindi_strokes.dart       46 Hindi paths
│   │                   tamil_strokes.dart       34 Tamil paths
│   ├── services/       update_checker, review_prompt, letter_audio, deep_link
│   ├── router/         GoRouter navigation
│   ├── theme/          AppTheme (Material 3)
│   ├── utils/          ResponsiveHelper (phone/tablet)
│   └── widgets/        AnimatedBackground
│
├── domain/             entities, repository contracts, use cases — no Flutter
├── data/               datasources, models, repository implementations
├── Presentation/
│   ├── blocs/          writing (the tracing engine), home, progress, music
│   ├── pages/          home, character_list (level map), writing_practice, onboarding
│   └── widgets/        drawing_canvas.dart, tracing_hand.dart
├── injection_container.dart
└── main.dart
```

> `Core/` and `Presentation/` are capitalised on disk. Import them exactly as
> spelt — macOS and Windows don't care, Ubuntu does, and 26 mis-cased imports
> once produced 185 analyzer errors on CI while building fine locally.

`writing_bloc.dart` is the heart of it: it decides whether a character is
guided or falls back to free tracing, builds the ink mask, and grades the
result. See [CLAUDE.md](CLAUDE.md) for how the tracing system works and how the
letter paths were authored.

## Setup

```bash
flutter pub get
flutter run
```

Fonts and audio are committed, so nothing needs downloading first.

### Regenerating the spoken audio

Both scripts read the letter tables directly, so they stay correct when a
letter is added:

```bash
pip install gtts
python3 scripts/generate_pronunciations.py   # letter sounds  → assets/audio/letters/
python3 scripts/generate_word_audio.py       # reward words   → assets/audio/words/
```

Existing clips are skipped. `--force` redoes everything, `--slow` gives a
clearer voice. `generate_pronunciations.py` also writes a `manifest.json`
recording which letter each clip belongs to — `test/letter_audio_test.dart`
compares it against the live table, which is what stops a clip quietly playing
the wrong letter after an insertion.

## Tests

```bash
flutter test
```

See [CI.md](CI.md) for what each file covers and what runs on CI.

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

**Android** — if you see `launch_background not found`, ensure
`android/app/src/main/res/drawable/launch_background.xml` and
`.../values/styles.xml` exist.

**iOS** — if `flutter_tts` causes a Swift Package Manager error:

```bash
flutter config --no-enable-swift-package-manager
flutter clean && flutter pub get
cd ios && pod install && cd ..
```

## Constraints

No ads, no IAP, no analytics, no third-party SDKs. This is a product decision
and the strongest line in the store listing — don't add one for convenience.
The app is in the Kids Category, so settings sit behind a long press rather
than a visible button.

## License

© 2026 Athul Sethumadhavan. All rights reserved.
