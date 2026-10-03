class Profile {
  final String sex;
  final int birthYear;
  final double heightCm;
  final double weightKg;
  final String activityLevel;
  final String goal;
  final String dietType;
  final List<String> allergies;
  final List<String> dislikedFoods;

  Profile({
    required this.sex,
    required this.birthYear,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
    required this.dietType,
    required this.allergies,
    required this.dislikedFoods,
  });

  Map<String, dynamic> toJson() => {
        'sex': sex,
        'birthYear': birthYear,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel,
        'goal': goal,
        'dietType': dietType,
        'allergies': allergies,
        'dislikedFoods': dislikedFoods,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        sex: j['sex'] as String? ?? 'other',
        birthYear: (j['birthYear'] as num? ?? 1990).toInt(),
        heightCm: (j['heightCm'] as num? ?? 170).toDouble(),
        weightKg: (j['weightKg'] as num? ?? 70).toDouble(),
        activityLevel: j['activityLevel'] as String? ?? 'moderate',
        goal: j['goal'] as String? ?? 'maintain',
        dietType: j['dietType'] as String? ?? 'omnivore',
        allergies: (j['allergies'] as List? ?? []).map((e) => e.toString()).toList(),
        dislikedFoods: (j['dislikedFoods'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}
