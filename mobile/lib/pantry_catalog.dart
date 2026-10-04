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
