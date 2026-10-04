import 'models/meal_plan.dart';

/// Backend olmadan uygulamayı gezebilmek için örnek (demo) veri.
/// Gerçek sürümde bu veriler backend'deki AI/fallback motorundan gelir.
class DemoData {
  static const List<Map<String, dynamic>> _breakfasts = [
    {
      'type': 'breakfast', 'name': 'Menemen', 'calories': 320,
      'protein_g': 18, 'carbs_g': 12, 'fat_g': 22,
      'ingredients': ['yumurta', 'domates', 'biber', 'zeytinyağı'],
      'recipe': 'Biberleri zeytinyağında kavur, domatesi ekle, yumurtaları kırıp karıştırarak pişir.',
    },
    {
      'type': 'breakfast', 'name': 'Yulaf ezmesi ve meyve', 'calories': 350,
      'protein_g': 12, 'carbs_g': 58, 'fat_g': 8,
      'ingredients': ['yulaf', 'süt', 'muz', 'bal'],
      'recipe': 'Yulafı sütle ısıt, dilimlenmiş muz ve bal ekle.',
    },
  ];

  static const List<Map<String, dynamic>> _mains = [
    {
      'type': 'lunch', 'name': 'Izgara tavuk ve bulgur pilavı', 'calories': 520,
      'protein_g': 45, 'carbs_g': 45, 'fat_g': 16,
      'ingredients': ['tavuk göğsü', 'bulgur', 'domates', 'soğan'],
      'recipe': 'Tavuğu baharatla ızgara yap; bulguru soğan ve domatesle pişir.',
    },
    {
      'type': 'dinner', 'name': 'Fırında somon ve sebze', 'calories': 480,
      'protein_g': 40, 'carbs_g': 12, 'fat_g': 30,
      'ingredients': ['somon', 'brokoli', 'limon', 'zeytinyağı'],
      'recipe': 'Somonu limon ve zeytinyağıyla fırınla; brokoliyi buharda pişir.',
    },
    {
      'type': 'dinner', 'name': 'Nohut yemeği ve pirinç', 'calories': 500,
      'protein_g': 19, 'carbs_g': 78, 'fat_g': 12,
      'ingredients': ['nohut', 'pirinç', 'soğan', 'salça'],
      'recipe': 'Soğanı kavur, salça ve nohudu ekle, pişir; pirinçle servis et.',
    },
  ];

  static const _labels = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  static Meal _meal(Map<String, dynamic> base) => Meal.fromJson(base);

  /// Seçilen süreye göre örnek yemek önerileri üretir (tamamen yerel, ağsız).
  static MealPlan buildPlan(String mode, String period) {
    final count = period == 'daily' ? 1 : (period == 'weekly' ? 7 : 30);
    final days = <DayPlan>[];
    final shopping = <String>{};

    for (var i = 0; i < count; i++) {
      final breakfast = _meal(_breakfasts[i % _breakfasts.length]);
      final lunch = _meal(_mains[i % _mains.length]);
      // Akşam öğününü öğleden farklı seç (çeşitlilik).
      final dinner = _meal(_mains[(i + 1) % _mains.length]);
      final meals = [breakfast, lunch, dinner];

      for (final m in meals) {
        shopping.addAll(m.ingredients);
      }

      days.add(DayPlan(
        day: i + 1,
        label: period == 'weekly' ? _labels[i % 7] : (count == 1 ? 'Bugün' : 'Gün ${i + 1}'),
        meals: meals,
        totalCalories: 0,
      ));
    }

    return MealPlan(
      id: 'demo',
      mode: mode,
      period: period,
      source: 'fallback',
      targetCalories: 0,
      summary: '(Demo) Evindeki malzemelere göre örnek yemek önerileri.',
      shoppingList: shopping.toList(),
      days: days,
    );
  }
}
