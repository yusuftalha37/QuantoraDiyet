import 'package:flutter/material.dart';

/// Görsel tema. Hedef kitle teknolojiye yabancı olduğu için her şey BÜYÜK,
/// yüksek kontrastlı ve okunaklı. Modern "smart" görünüm: krem arka plan,
/// yumuşak gölgeli yuvarlak kartlar, sıcak vurgu, akıcı sayfa geçişleri.
class AppTheme {
  // İştah açan sıcak turuncu — referans tasarımdaki ana renk.
  static const _seed = Color(0xFFE8743B);

  /// Vurgu rengi (ana renkle aynı aileden, turuncu).
  static const accent = Color(0xFFE8743B);

  /// Tamamlayıcı yeşil (bazı küçük detaylarda).
  static const green = Color(0xFF128C4B);

  /// Koyu "karşılama" kartı rengi (ana ekran hero).
  static const heroDark = Color(0xFF26211D);

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    ).copyWith(secondary: accent);

    // Krem / sıcak nötr yüzey (referans tasarımdaki gibi).
    final surface = isLight ? const Color(0xFFF5F2ED) : const Color(0xFF14110F);
    final card = isLight ? Colors.white : const Color(0xFF221E1B);

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      // Tüm yazıları büyüt (yaşlı/az teknoloji bilen kullanıcı için).
      textTheme: base.textTheme.apply(fontSizeFactor: 1.18),
      // Modern, akıcı sayfa geçişleri (her platformda).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        labelStyle: const TextStyle(fontSize: 17),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(62),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
