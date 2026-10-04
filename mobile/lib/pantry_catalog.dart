import 'package:flutter/material.dart';

/// Evdeki malzemeleri detaylı sormak için kategori + sık kullanılan öğeler.
class PantryCategory {
  final String title;
  final IconData icon;
  final List<String> items;
  const PantryCategory(this.title, this.icon, this.items);
}

const List<PantryCategory> kPantryCatalog = [
  PantryCategory('Sebzeler', Icons.eco, [
    'domates', 'salatalık', 'soğan', 'sarımsak', 'yeşil biber', 'kırmızı biber',
    'patates', 'havuç', 'patlıcan', 'kabak', 'ıspanak', 'brokoli', 'marul',
    'maydanoz', 'mantar', 'taze fasulye',
  ]),
  PantryCategory('Meyveler', Icons.apple, [
    'elma', 'muz', 'portakal', 'limon', 'çilek', 'üzüm', 'armut', 'mandalina',
    'avokado', 'kivi',
  ]),
  PantryCategory('Et, tavuk, balık, yumurta', Icons.set_meal, [
    'yumurta', 'tavuk göğsü', 'tavuk but', 'dana kıyma', 'dana eti', 'somon',
    'ton balığı', 'hindi', 'sucuk',
  ]),
  PantryCategory('Süt ürünleri', Icons.icecream, [
    'süt', 'yoğurt', 'beyaz peynir', 'kaşar peyniri', 'lor peyniri', 'tereyağı',
    'kaymak', 'ayran',
  ]),
  PantryCategory('Bakliyat & tahıl', Icons.rice_bowl, [
    'pirinç', 'bulgur', 'makarna', 'kırmızı mercimek', 'yeşil mercimek', 'nohut',
    'kuru fasulye', 'yulaf', 'un', 'ekmek', 'kuskus',
  ]),
  PantryCategory('Kuruyemiş & tohum', Icons.spa, [
    'ceviz', 'badem', 'fındık', 'yer fıstığı', 'susam', 'tahin', 'ay çekirdeği',
  ]),
  PantryCategory('Yağ & soslar', Icons.water_drop, [
    'zeytinyağı', 'ayçiçek yağı', 'tereyağı', 'salça', 'bal', 'reçel', 'ketçap',
  ]),
  PantryCategory('Baharatlar', Icons.grain, [
    'tuz', 'karabiber', 'pul biber', 'kimyon', 'nane', 'kekik', 'tarçın',
    'zerdeçal', 'köri',
  ]),
];

/// Hemen her evde bulunan temel malzemeler (mevsimden bağımsız).
const List<String> _staples = [
  'yumurta', 'süt', 'yoğurt', 'beyaz peynir', 'un', 'pirinç', 'bulgur',
  'makarna', 'kırmızı mercimek', 'nohut', 'soğan', 'sarımsak', 'patates',
  'salça', 'zeytinyağı', 'tuz', 'karabiber', 'tavuk göğsü', 'dana kıyma',
];

/// İçinde bulunulan aya göre mevsim etiketi.
String seasonLabel([DateTime? now]) {
  final m = (now ?? DateTime.now()).month;
  if (m == 12 || m <= 2) return 'kış';
  if (m <= 5) return 'ilkbahar';
  if (m <= 8) return 'yaz';
  return 'sonbahar';
}

/// Mevsime göre taze ürünler.
List<String> _seasonalProduce([DateTime? now]) {
  switch (seasonLabel(now)) {
    case 'kış':
      return ['lahana', 'karnabahar', 'brokoli', 'ıspanak', 'pırasa', 'havuç',
        'portakal', 'mandalina', 'elma', 'limon'];
    case 'ilkbahar':
      return ['ıspanak', 'marul', 'bezelye', 'taze soğan', 'maydanoz',
        'çilek', 'kabak', 'havuç'];
    case 'yaz':
      return ['domates', 'salatalık', 'yeşil biber', 'patlıcan', 'kabak',
        'taze fasulye', 'biber', 'limon'];
    default: // sonbahar
      return ['patlıcan', 'yeşil biber', 'domates', 'elma', 'üzüm', 'lahana',
        'karnabahar', 'ıspanak', 'havuç'];
  }
}

/// "Atla" seçilince kullanılan: ortalama ev malzemeleri + mevsim ürünleri.
List<String> seasonalDefaultPantry([DateTime? now]) {
  final set = <String>{..._staples, ..._seasonalProduce(now)};
  return set.toList();
}
