# ✏️ KidWrite — Flutter Writing Practice App

A fun, animated writing practice app for kids below 6, supporting English, Malayalam, Hindi, Tamil, and Numbers.

## Privacy

KidWrite does not collect any personal data. All progress is stored locally on the device and never transmitted. The app works fully offline and contains no ads or in-app purchases.

🔗 [Privacy Policy](https://athulsethumadhavan.github.io/KidWrite/privacy_policy.html)

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

- 5 language packs: English (A–Z, a–z), Numbers (0–9), Malayalam, Hindi (Devanagari), Tamil
- Trace-to-write canvas with faded guide character and smooth Bézier stroke rendering
- Per-character progress tracking with star/mastery badges (persisted via SharedPreferences)
- Confetti celebration on successful traces
- Looping background music with mute toggle
- Animated floating-bubble background with per-language colour themes
- Responsive layouts for phones and tablets/iPads
- Clean Architecture + MVVM + BLoC throughout (GetIt DI)

## Running tests

```bash
flutter test
```

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