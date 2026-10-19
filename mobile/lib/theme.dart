import 'package:flutter/material.dart';

/// Tasarım sistemi — "Sıcak kâğıt, mürekkep, tek vurgu".
/// Sade, niyetli, yüksek kontrastlı. Dekoratif cam/degrade/leke YOK.
/// Hedef kitle teknolojiye yabancı olduğu için yazılar iri ve net,
/// dokunma alanları büyük, hiyerarşi tipografi ve boşlukla kurulur.
class AppColors {
  final Color paper; // ekran zemini
  final Color surface; // kart yüzeyi
  final Color ink; // ana metin
  final Color inkMuted; // ikincil metin
  final Color hairline; // ince ayraç/kenar
  final Color accent; // tek vurgu (terracotta)
  final Color accentWeak; // vurgunun çok açık zemini

  const AppColors({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.hairline,
    required this.accent,
    required this.accentWeak,
  });

  static const light = AppColors(
    paper: Color(0xFFFBF7F1),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF211D1A),
    inkMuted: Color(0xFF6F6457),
    hairline: Color(0xFFE7E0D4),
    accent: Color(0xFFBC5631),
    accentWeak: Color(0xFFF4E7DE),
  );

  static const dark = AppColors(
    paper: Color(0xFF14120F),
    surface: Color(0xFF1E1B17),
    ink: Color(0xFFEDE7DD),
    inkMuted: Color(0xFFA79B8C),
    hairline: Color(0xFF302B24),
    accent: Color(0xFFDE7A4F),
    accentWeak: Color(0xFF2A211B),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Öğün kategorileri için sakin, az doygun renkler — büyük renkli şeritler
/// yerine küçük bir nokta/etiket olarak kullanılır.
class MealTone {
  static const Map<String, Color> _c = {
    'breakfast': Color(0xFFB07D24),
    'lunch': Color(0xFF3E7C50),
    'dinner': Color(0xFFBC5631),
    'snack': Color(0xFF3E8079),
  };
  static Color of(String type) => _c[type] ?? const Color(0xFF6F6457);
}

class AppTheme {
  /// Geriye dönük uyum için vurgu rengi (açık tema).
  static const accent = Color(0xFFBC5631);

  static ThemeData light() => _base(AppColors.light, Brightness.light);
  static ThemeData dark() => _base(AppColors.dark, Brightness.dark);

  static ThemeData _base(AppColors c, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
    ).copyWith(
      primary: c.accent,
      surface: c.surface,
      onSurface: c.ink,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    // Ölçekli, niyetli tipografi. Hedef kitle için okunaklı-iri ama abartısız.
    final t = base.textTheme;
    final text = t.copyWith(
      headlineSmall: t.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: c.ink, height: 1.2),
      titleLarge: t.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: c.ink),
      titleMedium: t.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 17, height: 1.45, color: c.ink),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 15, height: 1.45, color: c.inkMuted),
      labelLarge: t.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    ).apply(bodyColor: c.ink, displayColor: c.ink);

    return base.copyWith(
      scaffoldBackgroundColor: c.paper,
      textTheme: text,
      dividerTheme: DividerThemeData(color: c.hairline, thickness: 1, space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.paper,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(color: c.ink, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.hairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: TextStyle(fontSize: 16, color: c.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: c.hairline),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: const TextStyle(fontSize: 15, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
