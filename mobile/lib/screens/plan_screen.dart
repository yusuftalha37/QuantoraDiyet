import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/meal_plan.dart';
import '../recipes.dart';
import '../utils/scale.dart';
import '../services/tts_service.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Yemek Önerilerin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoBox(singleDay: singleDay),
          const SizedBox(height: 14),
          _ServingsCard(
            servings: _servings,
            onChanged: (v) => setState(() => _servings = v),
          ),
          const SizedBox(height: 12),
          _ShoppingButton(items: _shopping),
          const SizedBox(height: 20),
          if (singleDay)
            ...List.generate(
              _meals.first.length,
              (i) => _MealCard(
                meal: _meals.first[i],
                servings: _servings,
                onSwap: () => _swap(0, i),
              ),
            )
          else
            ...List.generate(_meals.length, (d) => _DayCard(
                  label: _labels[d],
                  dayNo: _dayNos[d],
                  meals: _meals[d],
                  servings: _servings,
                  onSwap: (i) => _swap(d, i),
                )),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final bool singleDay;
  const _InfoBox({required this.singleDay});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👩‍🍳', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              singleDay
                  ? 'İşte bugün pişirebileceğin yemekler. Beğenmezsen "🔄 Başka" '
                      'ile değiştir. Yapmak istediğine "👨‍🍳 Adım adım pişir"e dokun.'
                  : 'Her gün için yemekler var. Bir güne DOKUN, açılsın. Beğenmediğini '
                      '"🔄 Başka" ile değiştirebilirsin.',
              style: TextStyle(fontSize: 16, color: scheme.onSecondaryContainer, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServingsCard extends StatelessWidget {
  final int servings;
  final ValueChanged<int> onChanged;
  const _ServingsCard({required this.servings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Text('👥', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Kaç kişilik?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            IconButton.filledTonal(
              iconSize: 28,
              onPressed: servings > 1 ? () => onChanged(servings - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 44,
              child: Text('$servings',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            IconButton.filledTonal(
              iconSize: 28,
              onPressed: servings < 20 ? () => onChanged(servings + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingButton extends StatelessWidget {
  final List<String> items;
  const _ShoppingButton({required this.items});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _ShoppingScreen(items: items)),
      ),
      icon: const Text('🛒', style: TextStyle(fontSize: 26)),
      label: const Text('Alışveriş Listem'),
    );
  }
}

String _mealEmoji(String type) => switch (type) {
      'breakfast' => '🍳',
      'lunch' => '🍲',
      'dinner' => '🍽️',
      'snack' => '🥗',
      _ => '🥄',
    };

Color _mealColor(String type, ColorScheme s) => switch (type) {
      'breakfast' => const Color(0xFFE8A317),
      'lunch' => const Color(0xFF2F9E5B),
      'dinner' => const Color(0xFFD86A3C),
      'snack' => const Color(0xFF2B9E8D),
      _ => s.primary,
    };

String _mealLabel(String type) => switch (type) {
      'breakfast' => 'KAHVALTI',
      'lunch' => 'ÖĞLE YEMEĞİ',
      'dinner' => 'AKŞAM YEMEĞİ',
      'snack' => 'YANINDA / ARA',
      _ => 'YEMEK',
    };

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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        initiallyExpanded: dayNo == 1,
        leading: const Text('📅', style: TextStyle(fontSize: 28)),
        title: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text('👉 Dokun, ${meals.length} yemeği gör',
            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: List.generate(
          meals.length,
          (i) => _MealCard(meal: meals[i], servings: servings, onSwap: () => onSwap(i)),
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
    final scheme = Theme.of(context).colorScheme;
    final color = _mealColor(meal.type, scheme);
    final factor = _factor;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Renkli başlık + "Başka öner"
          Container(
            width: double.infinity,
            color: color,
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Text(_mealEmoji(meal.type), style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_mealLabel(meal.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          )),
                      Text(meal.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onSwap,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Text('🔄', style: TextStyle(fontSize: 18)),
                  label: const Text('Başka', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meal.prepMinutes != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _pill(context, '⏱️ ${meal.prepMinutes} dakika'),
                  ),

                // NELER GEREKİYOR
                Row(children: [
                  const Text('🧺 ', style: TextStyle(fontSize: 18)),
                  Text('NELER GEREKİYOR? ($servings kişilik)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scheme.primary)),
                ]),
                const SizedBox(height: 6),
                ...meal.ingredients.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  ', style: TextStyle(fontSize: 18)),
                          Expanded(
                              child: Text(scaleIngredient(i, factor),
                                  style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    )),

                const SizedBox(height: 14),
                // NASIL YAPILIR
                Row(children: [
                  const Text('👨‍🍳 ', style: TextStyle(fontSize: 18)),
                  Text('NASIL YAPILIR?',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scheme.primary)),
                ]),
                const SizedBox(height: 8),
                if (meal.steps.isNotEmpty)
                  ...List.generate(meal.steps.length,
                      (i) => _StepRow(index: i + 1, text: meal.steps[i], color: color))
                else
                  Text(meal.recipe, style: const TextStyle(fontSize: 16, height: 1.35)),

                const SizedBox(height: 12),
                // Adım adım pişir + Sesli oku
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CookingModeScreen(meal: meal)),
                        ),
                        icon: const Text('👨‍🍳', style: TextStyle(fontSize: 20)),
                        label: const Text('Adım adım pişir'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        onPressed: () => TtsService.speak(
                          meal.steps.isNotEmpty ? meal.steps.join('. ') : meal.recipe,
                        ),
                        child: const Text('📢 Oku', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String text;
  final Color color;
  const _StepRow({required this.index, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text('$index',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, height: 1.35))),
        ],
      ),
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
    final buffer = StringBuffer('🛒 Alışveriş Listem\n\n');
    for (final item in widget.items) {
      buffer.writeln('• $item');
    }
    buffer.writeln('\n(Bugün Ne Pişirsem? uygulaması)');
    Share.share(buffer.toString(), subject: 'Alışveriş Listem');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alışveriş Listesi')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✅', style: TextStyle(fontSize: 64)),
                SizedBox(height: 14),
                Text('Markete gitmene gerek yok!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Bu yemekler için gereken her şey evinde var.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    final total = widget.items.length;
    final done = _checked.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Alışveriş Listesi')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _share,
            icon: const Text('📲', style: TextStyle(fontSize: 24)),
            label: const Text('Listeyi Paylaş (WhatsApp vb.)'),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: scheme.primaryContainer,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🛒 Markete gidince bunları al',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
                const SizedBox(height: 4),
                Text('Aldığın şeyin üstüne dokun; çizilsin.',
                    style: TextStyle(fontSize: 15, color: scheme.onPrimaryContainer)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: 10,
                    backgroundColor: scheme.surface,
                  ),
                ),
                const SizedBox(height: 6),
                Text('$done / $total alındı',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final checked = _checked.contains(i);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  onTap: () => setState(() => checked ? _checked.remove(i) : _checked.add(i)),
                  leading: Icon(
                    checked ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: checked ? scheme.primary : scheme.outline,
                    size: 30,
                  ),
                  title: Text(
                    widget.items[i],
                    style: TextStyle(
                      fontSize: 18,
                      decoration: checked ? TextDecoration.lineThrough : null,
                      color: checked ? Theme.of(context).disabledColor : null,
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
