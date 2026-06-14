class AppConstants {
  AppConstants._();

  // App metadata
  static const String appName = 'KidWrite';
  static const String appVersion = '1.0.0';

  // Shared prefs keys
  static const String prefSelectedLanguage = 'selected_language';
  static const String prefProgressPrefix = 'progress_';
  static const String prefMusicEnabled = 'music_enabled';
  static const String prefSoundEnabled = 'sound_enabled';

  // Animation durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration celebrationDuration = Duration(seconds: 2);
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);

  // Canvas
  static const double strokeWidth = 10.0;
  static const double guideStrokeWidth = 3.0;
  static const double canvasPadding = 24.0;
  // Accuracy threshold (0.0–1.0): fraction of guide points hit
  static const double successThreshold = 0.75;

  // Layout
  static const double cardBorderRadius = 24.0;
  static const double buttonBorderRadius = 16.0;
  static const double iconSize = 40.0;

  // Audio asset paths (place files under assets/audio/)
  static const String bgMusicPath = 'audio/bg_music.mp3';
  static const String successSoundPath = 'audio/success.mp3';
  static const String tapSoundPath = 'audio/tap.mp3';
  static const String clearSoundPath = 'audio/clear.mp3';
}

/// Supported language IDs
class LanguageId {
  LanguageId._();
  static const String english = 'english';
  static const String malayalam = 'malayalam';
  static const String hindi = 'hindi';
  static const String tamil = 'tamil';
  static const String numbers = 'numbers';
}
