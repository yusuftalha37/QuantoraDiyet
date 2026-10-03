import 'models/meal_plan.dart';

/// Backend olmadan uygulamayı gezebilmek için örnek (demo) veri.
/// Gerçek sürümde bu veriler backend'deki AI/fallback motorundan gelir.
class DemoData {
  static const Map<String, dynamic> targets = {
    'bmr': 1450,
    'tdee': 2250,
    'targetCalories': 1800,
    'macros': {'proteinG': 135, 'carbsG': 180, 'fatG': 60},
  };

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

  static const List<Map<String, dynamic>> _snacks = [
    {
      'type': 'snack', 'name': 'Yoğurt ve ceviz', 'calories': 220,
      'protein_g': 10, 'carbs_g': 16, 'fat_g': 13,
      'ingredients': ['yoğurt', 'ceviz', 'bal'],
      'recipe': 'Yoğurdun üzerine ceviz ve bal ekle.',
    },
    {
      'type': 'snack', 'name': 'Mevsim meyvesi', 'calories': 120,
      'protein_g': 1, 'carbs_g': 30, 'fat_g': 0,
      'ingredients': ['elma', 'portakal'],
      'recipe': 'Meyveleri yıka ve dilimle.',
    },
  ];

  static const _labels = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  /// Seçilen tür/süreye göre örnek bir plan üretir (tamamen yerel, ağsız).
  static MealPlan buildPlan(String mode, String period) {
    final count = period == 'daily' ? 1 : (period == 'weekly' ? 7 : 30);
    final days = <DayPlan>[];
    final shopping = <String>{};

    for (var i = 0; i < count; i++) {
      final breakfast = Meal.fromJson(_breakfasts[i % _breakfasts.length]);
      final lunch = Meal.fromJson(_mains[i % _mains.length]);
      final dinner = Meal.fromJson(_mains[(i + 1) % _mains.length]);
      final snack = Meal.fromJson(_snacks[i % _snacks.length]);
      final meals = [breakfast, lunch, dinner, snack];
      final total = meals.fold<int>(0, (a, m) => a + m.calories);

      for (final m in meals) {
        shopping.addAll(m.ingredients);
      }

      days.add(DayPlan(
        day: i + 1,
        label: period == 'weekly' ? _labels[i % 7] : 'Gün ${i + 1}',
        meals: meals,
        totalCalories: total,
      ));
    }

    return MealPlan(
      id: 'demo',
      mode: mode,
      period: period,
      source: 'fallback',
      targetCalories: 1800,
      summary: mode == 'diet'
          ? '(Demo) Hedefe uygun ~1800 kcal/gün örnek diyet planı.'
          : '(Demo) Pratik ev yemeği örnek planı.',
      shoppingList: shopping.toList(),
      days: days,
    );
  }
}
