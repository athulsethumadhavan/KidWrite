import 'package:flutter_tts/flutter_tts.dart';

/// Wraps FlutterTts with per-language locale selection and kid-friendly
/// speech settings (slower rate, slightly raised pitch).
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialised = false;

  Future<void> _ensureInit() async {
    if (_initialised) return;
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45); // slower — easier for young kids to follow
    await _tts.setPitch(1.1);       // slightly brighter, friendlier tone
    _initialised = true;
  }

  /// Speak [text] using the locale that matches [languageId].
  Future<void> speak(String text, String languageId) async {
    await _ensureInit();
    await _tts.setLanguage(_localeFor(languageId));
    await _tts.stop(); // cancel any in-progress utterance first
    await _tts.speak(text);
  }

  Future<void> stop() async => _tts.stop();

  /// Maps app language IDs → BCP-47 locale tags.
  static String _localeFor(String languageId) {
    switch (languageId) {
      case 'malayalam':
        return 'ml-IN';
      case 'hindi':
        return 'hi-IN';
      case 'tamil':
        return 'ta-IN';
      default:
        return 'en-US'; // english + numbers
    }
  }
}
