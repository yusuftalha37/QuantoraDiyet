/// Malzeme metnindeki baştaki sayıyı [factor] ile ölçekler.
/// Örn. ("3 yumurta", 2) -> "6 yumurta"; ("1 su bardağı süt", 2) -> "2 su bardağı süt".
/// Baştaki sayı yoksa (tuz, zeytinyağı) metni aynen döndürür.
String scaleIngredient(String text, double factor) {
  if (factor == 1.0) return text;
  final t = text.trim();
  final m = RegExp(r'^(\d+([.,]\d+)?)').firstMatch(t);
  if (m == null) return text;
  // "6-8 dilim" gibi aralıkları bozma.
  if (m.end < t.length && t[m.end] == '-') return text;
  final value = double.parse(m.group(1)!.replaceAll(',', '.'));
  final scaled = value * factor;
  final rounded = (scaled * 2).round() / 2; // 0.5'lik adımlara yuvarla
  final display = rounded % 1 == 0 ? rounded.toInt().toString() : rounded.toString();
  return '$display${t.substring(m.end)}';
}
