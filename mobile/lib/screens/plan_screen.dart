import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/meal_plan.dart';
import '../recipes.dart';
import '../utils/scale.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'cooking_mode_screen.dart';

class PlanScreen extends StatefulWidget {
  final MealPlan plan;
  const PlanScreen({super.key, required this.plan});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late List<List<Meal>> _meals; // gün -> öğünler (değiştirilebilir)
  late List<String> _labels;
  late List<int> _dayNos;
  int _servings = 4;

  @override
  void initState() {
    super.initState();
    _labels = widget.plan.days.map((d) => d.label).toList();
    _dayNos = widget.plan.days.map((d) => d.day).toList();
    _meals = widget.plan.days.map((d) => List<Meal>.of(d.meals)).toList();
    final s = widget.plan.days.first.meals
        .firstWhere((m) => m.servings != null, orElse: () => widget.plan.days.first.meals.first)
        .servings;
    _servings = s ?? 4;
  }

  List<Map<String, dynamic>> _poolFor(String type) => switch (type) {
        'breakfast' => RecipeCatalog.breakfasts,
        'snack' => RecipeCatalog.extras,
        _ => RecipeCatalog.mains,
      };

  void _swap(int day, int mealIdx) {
    final meal = _meals[day][mealIdx];
    final pool = _poolFor(meal.type);
    if (pool.isEmpty) return;
    final used = _meals[day].map((m) => m.name).toSet();
    final start = pool.indexWhere((e) => e['name'] == meal.name);
    for (var step = 1; step <= pool.length; step++) {
      final cand = pool[(start + step) % pool.length];
      if (cand['name'] == meal.name || used.contains(cand['name'])) continue;
      setState(() => _meals[day][mealIdx] = Meal.fromJson(cand));
      return;
    }
    for (final cand in pool) {
      if (cand['name'] != meal.name) {
        setState(() => _meals[day][mealIdx] = Meal.fromJson(cand));
        return;
      }
    }
  }

  List<String> get _shopping {
    final set = <String>{};
    for (final day in _meals) {
      for (final m in day) {
        set.addAll(m.ingredients);
      }
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    final singleDay = _meals.length == 1;
    final shopping = _shopping;
    return Scaffold(
      appBar: AppBar(title: const Text('Önerilerin')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            singleDay
                ? 'Bugün için yemekler hazır. Beğenmediğini değiştir, yapmak istediğini adım adım pişir.'
                : 'Her gün için yemekler hazır. Bir güne dokun, aç.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _ServingsRow(
            servings: _servings,
            onChanged: (v) => setState(() => _servings = v),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _ShoppingScreen(items: shopping)),
            ),
            icon: const Icon(Icons.shopping_basket_outlined, size: 20),
            label: Text('Alışveriş listesi · ${shopping.length} ürün'),
          ),
          const SizedBox(height: 24),
          if (singleDay)
            for (var i = 0; i < _meals.first.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _MealCard(meal: _meals.first[i], servings: _servings, onSwap: () => _swap(0, i)),
            ]
          else
            for (var d = 0; d < _meals.length; d++) ...[
              if (d > 0) const SizedBox(height: 12),
              _DayCard(
                label: _labels[d],
                dayNo: _dayNos[d],
                meals: _meals[d],
                servings: _servings,
                onSwap: (i) => _swap(d, i),
              ),
            ],
        ],
      ),
    );
  }
}

String _mealLabel(String type) => switch (type) {
      'breakfast' => 'Kahvaltı',
      'lunch' => 'Öğle yemeği',
      'dinner' => 'Akşam yemeği',
      'snack' => 'Yanında / ara',
      _ => 'Yemek',
    };

class _ServingsRow extends StatelessWidget {
  final int servings;
  final ValueChanged<int> onChanged;
  const _ServingsRow({required this.servings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Expanded(
            child: Text('Kaç kişilik?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
          _StepButton(icon: Icons.remove_rounded, onTap: servings > 1 ? () => onChanged(servings - 1) : null),
          SizedBox(
            width: 40,
            child: Text('$servings',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: servings < 20 ? () => onChanged(servings + 1) : null),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: enabled ? c.hairline : c.hairline.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: enabled ? c.ink : c.inkMuted.withOpacity(0.5)),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String label;
  final int dayNo;
  final List<Meal> meals;
  final int servings;
  final ValueChanged<int> onSwap;
  const _DayCard({
    required this.label,
    required this.dayNo,
    required this.meals,
    required this.servings,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          initiallyExpanded: dayNo == 1,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('${meals.length} yemek', style: TextStyle(color: c.inkMuted, fontSize: 14)),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            for (var i = 0; i < meals.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _MealCard(meal: meals[i], servings: servings, onSwap: () => onSwap(i)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  final int servings;
  final VoidCallback onSwap;
  const _MealCard({required this.meal, required this.servings, required this.onSwap});

  double get _factor {
    final base = meal.servings;
    if (base == null || base <= 0) return 1.0;
    return servings / base;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tone = MealTone.of(meal.type);
    final factor = _factor;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık: kategori noktası + etiket + isim, sağda değiştir.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        MealDot(tone),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _mealLabel(meal.type).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: c.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(meal.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onSwap,
                style: TextButton.styleFrom(
                  foregroundColor: c.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                icon: const Icon(Icons.autorenew_rounded, size: 18),
                label: const Text('Değiştir'),
              ),
            ],
          ),

          if (meal.prepMinutes != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 17, color: c.inkMuted),
                const SizedBox(width: 6),
                Text('${meal.prepMinutes} dakika',
                    style: TextStyle(fontSize: 14.5, color: c.inkMuted, fontWeight: FontWeight.w500)),
              ],
            ),
          ],

          const SizedBox(height: 16),
          Divider(height: 1, color: c.hairline),
          const SizedBox(height: 16),

          Row(
            children: [
              const SectionLabel('Malzemeler'),
              const SizedBox(width: 8),
              Text('· $servings kişilik',
                  style: TextStyle(fontSize: 13, color: c.inkMuted, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          ...meal.ingredients.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 10),
                      child: MealDot(c.inkMuted, size: 5),
                    ),
                    Expanded(
                        child: Text(scaleIngredient(i, factor),
                            style: const TextStyle(fontSize: 16, height: 1.35))),
                  ],
                ),
              )),

          const SizedBox(height: 18),
          const SectionLabel('Yapılışı'),
          const SizedBox(height: 10),
          if (meal.steps.isNotEmpty)
            for (var i = 0; i < meal.steps.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _StepRow(index: i + 1, text: meal.steps[i]),
            ]
          else
            Text(meal.recipe, style: const TextStyle(fontSize: 16, height: 1.4)),

          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CookingModeScreen(meal: meal)),
            ),
            icon: const Icon(Icons.local_fire_department_rounded, size: 20),
            label: const Text('Adım adım pişir'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => TtsService.speak(
              meal.steps.isNotEmpty ? meal.steps.join('. ') : meal.recipe,
            ),
            icon: const Icon(Icons.volume_up_rounded, size: 20),
            label: const Text('Sesli oku'),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String text;
  const _StepRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.accentWeak,
            shape: BoxShape.circle,
          ),
          child: Text('$index',
              style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16, height: 1.4))),
      ],
    );
  }
}

class _ShoppingScreen extends StatefulWidget {
  final List<String> items;
  const _ShoppingScreen({required this.items});
  @override
  State<_ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<_ShoppingScreen> {
  final Set<int> _checked = {};

  void _share() {
    final buffer = StringBuffer('Alışveriş Listem\n\n');
    for (final item in widget.items) {
      buffer.writeln('- $item');
    }
    buffer.writeln('\n(Bugün Ne Pişirsem? uygulaması)');
    Share.share(buffer.toString(), subject: 'Alışveriş Listem');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (widget.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alışveriş listesi')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 40, color: c.inkMuted),
                const SizedBox(height: 14),
                Text('Markete gerek yok',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('Bu yemekler için gereken her şey evinde var.',
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
    }

    final total = widget.items.length;
    final done = _checked.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Alışveriş listesi')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton.icon(
          onPressed: _share,
          icon: const Icon(Icons.ios_share_rounded, size: 20),
          label: const Text('Listeyi paylaş'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aldığın ürüne dokun; üstü çizilir.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: 6,
                    backgroundColor: c.hairline,
                    valueColor: AlwaysStoppedAnimation(c.accent),
                  ),
                ),
                const SizedBox(height: 6),
                Text('$done / $total alındı',
                    style: TextStyle(fontSize: 13.5, color: c.inkMuted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: c.hairline),
              itemBuilder: (_, i) {
                final checked = _checked.contains(i);
                return InkWell(
                  onTap: () => setState(() => checked ? _checked.remove(i) : _checked.add(i)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          checked ? Icons.check_circle_rounded : Icons.circle_outlined,
                          color: checked ? c.accent : c.inkMuted,
                          size: 26,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            widget.items[i],
                            style: TextStyle(
                              fontSize: 17,
                              decoration: checked ? TextDecoration.lineThrough : null,
                              color: checked ? c.inkMuted : c.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
