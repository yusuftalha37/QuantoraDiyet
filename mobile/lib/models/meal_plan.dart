class Meal {
  final String type;
  final String name;
  final List<String> ingredients;
  final String recipe;
  final List<String> steps;
  final int? prepMinutes;
  final int? servings;
  final int calories;
  final num proteinG;
  final num carbsG;
  final num fatG;

  Meal({
    required this.type,
    required this.name,
    required this.ingredients,
    required this.recipe,
    this.steps = const [],
    this.prepMinutes,
    this.servings,
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  factory Meal.fromJson(Map<String, dynamic> j) {
    final steps = (j['steps'] as List? ?? []).map((e) => e.toString()).toList();
    final recipe = (j['recipe'] as String?) ?? (steps.isNotEmpty ? steps.join('\n') : '');
    return Meal(
      type: j['type'] as String? ?? 'meal',
      name: j['name'] as String? ?? '',
      ingredients: (j['ingredients'] as List? ?? []).map((e) => e.toString()).toList(),
      recipe: recipe,
      steps: steps,
      prepMinutes: (j['prep_minutes'] as num?)?.toInt(),
      servings: (j['servings'] as num?)?.toInt(),
      calories: (j['calories'] as num? ?? 0).toInt(),
      proteinG: j['protein_g'] as num? ?? 0,
      carbsG: j['carbs_g'] as num? ?? 0,
      fatG: j['fat_g'] as num? ?? 0,
    );
  }

  String get typeLabel => switch (type) {
        'breakfast' => 'Kahvaltı',
        'lunch' => 'Öğle',
        'dinner' => 'Akşam',
        'snack' => 'Ara öğün',
        _ => 'Öğün',
      };
}

class DayPlan {
  final int day;
  final String label;
  final List<Meal> meals;
  final int totalCalories;

  DayPlan({required this.day, required this.label, required this.meals, required this.totalCalories});

  factory DayPlan.fromJson(Map<String, dynamic> j) => DayPlan(
        day: (j['day'] as num? ?? 1).toInt(),
        label: j['label'] as String? ?? 'Gün',
        meals: (j['meals'] as List? ?? []).map((e) => Meal.fromJson(e as Map<String, dynamic>)).toList(),
        totalCalories: (j['total_calories'] as num? ?? 0).toInt(),
      );
}

class MealPlan {
  final String id;
  final String mode;
  final String period;
  final String source;
  final int targetCalories;
  final String summary;
  final List<String> shoppingList;
  final List<DayPlan> days;

  MealPlan({
    required this.id,
    required this.mode,
    required this.period,
    required this.source,
    required this.targetCalories,
    required this.summary,
    required this.shoppingList,
    required this.days,
  });

  factory MealPlan.fromResponse(Map<String, dynamic> j) {
    final plan = (j['plan'] as Map<String, dynamic>? ?? {});
    return MealPlan(
      id: j['id'] as String? ?? '',
      mode: j['mode'] as String? ?? '',
      period: j['period'] as String? ?? '',
      source: j['source'] as String? ?? '',
      targetCalories: (j['targetCalories'] as num? ?? plan['target_calories'] as num? ?? 0).toInt(),
      summary: plan['summary'] as String? ?? '',
      shoppingList: (plan['shopping_list'] as List? ?? []).map((e) => e.toString()).toList(),
      days: (plan['days'] as List? ?? []).map((e) => DayPlan.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  String get sourceLabel => source == 'ai' ? 'Yapay zekâ' : 'Çevrimdışı motor';
}
