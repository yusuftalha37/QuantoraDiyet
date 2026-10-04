import 'models/meal_plan.dart';
import 'recipes.dart';

/// Backend olmadan uygulamayı gezebilmek için örnek (demo) veri.
/// Zengin tarif kataloğundan çeşitli öneriler üretir.
class DemoData {
  static const _labels = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  static Meal _meal(Map<String, dynamic> base) => Meal.fromJson(base);

  /// Seçilen süreye göre örnek yemek önerileri üretir (tamamen yerel, ağsız).
  static MealPlan buildPlan(String mode, String period) {
    final count = period == 'daily' ? 1 : (period == 'weekly' ? 7 : 30);
    final b = RecipeCatalog.breakfasts;
    final m = RecipeCatalog.mains;
    final e = RecipeCatalog.extras;

    final days = <DayPlan>[];
    final shopping = <String>{};

    for (var i = 0; i < count; i++) {
      final breakfast = _meal(b[i % b.length]);
      final lunch = _meal(m[(i * 2) % m.length]);
      final dinner = _meal(m[(i * 2 + 1) % m.length]); // öğleden farklı
      final side = _meal(e[i % e.length]);
      final meals = [breakfast, lunch, dinner, side];

      for (final meal in meals) {
        shopping.addAll(meal.ingredients);
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
