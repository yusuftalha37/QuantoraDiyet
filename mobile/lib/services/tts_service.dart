import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

/// Tarif adımlarını Türkçe sesli okur.
/// Not: Sesin kalitesi telefonun yüklü TTS motoruna (ör. Google) bağlıdır;
/// burada mevcut en iyi Türkçe sesi seçip hız/tonu ayarlıyoruz.
class TtsService {
  TtsService._();
  static final _tts = FlutterTts();
  static bool _ready = false;

  static Future<void> _ensure() async {
    if (_ready) return;
    try {
      // Android'de mümkünse Google TTS motorunu kullan (daha doğal ses).
      if (Platform.isAndroid) {
        try {
          final engines = (await _tts.getEngines) as List?;
          if (engines != null && engines.contains('com.google.android.tts')) {
            await _tts.setEngine('com.google.android.tts');
          }
        } catch (_) {}
      }

      await _tts.setLanguage('tr-TR');
      await _tts.awaitSpeakCompletion(true);
      await _pickBestTurkishVoice();
      await _tts.setSpeechRate(0.5); // daha anlaşılır
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
    } catch (_) {}
    _ready = true;
  }

  /// Türkçe sesler arasından en iyisini seçmeye çalışır (varsa "network"/gelişmiş).
  static Future<void> _pickBestTurkishVoice() async {
    try {
      final voices = (await _tts.getVoices) as List?;
      if (voices == null) return;
      final tr = voices
          .whereType<Map>()
          .map((v) => v.map((k, val) => MapEntry(k.toString(), val.toString())))
          .where((v) => (v['locale'] ?? '').toLowerCase().startsWith('tr'))
          .toList();
      if (tr.isEmpty) return;

      // Öncelik: adında "network" (gelişmiş/doğal) geçen; yoksa ilk Türkçe ses.
      final best = tr.firstWhere(
        (v) => (v['name'] ?? '').toLowerCase().contains('network'),
        orElse: () => tr.first,
      );
      await _tts.setVoice({'name': best['name']!, 'locale': best['locale']!});
    } catch (_) {}
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
