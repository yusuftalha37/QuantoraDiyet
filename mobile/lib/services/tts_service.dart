import 'package:flutter_tts/flutter_tts.dart';

/// Tarif adımlarını Türkçe sesli okur.
class TtsService {
  TtsService._();
  static final _tts = FlutterTts();
  static bool _ready = false;

  static Future<void> _ensure() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    } catch (_) {}
    _ready = true;
  }

  static Future<void> speak(String text) async {
    await _ensure();
    await _tts.stop();
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
