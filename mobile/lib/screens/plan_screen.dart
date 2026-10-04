import 'package:flutter/material.dart';
import '../models/meal_plan.dart';

class PlanScreen extends StatelessWidget {
  final MealPlan plan;
  const PlanScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yemek önerileri'),
          bottom: const TabBar(tabs: [Tab(text: 'Yemekler'), Tab(text: 'Alışveriş')]),
        ),
        body: TabBarView(
          children: [_DaysTab(plan: plan), _ShoppingTab(items: plan.shoppingList)],
        ),
      ),
    );
  }
}

class _DaysTab extends StatelessWidget {
  final MealPlan plan;
  const _DaysTab({required this.plan});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(plan.summary),
          ),
        ),
        const SizedBox(height: 8),
        ...plan.days.map((d) => _DayCard(day: d)),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final DayPlan day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        initiallyExpanded: day.day == 1,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Text('📅', style: TextStyle(fontSize: 18)),
        ),
        title: Text(day.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('${day.meals.length} öğün önerisi'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: day.meals.map((m) => _MealTile(meal: m)).toList(),
      ),
    );
  }
}

String _mealEmoji(String type) => switch (type) {
      'breakfast' => '🍳',
      'lunch' => '🍲',
      'dinner' => '🍽️',
      'snack' => '🍎',
      _ => '🥄',
    };

class _MealTile extends StatelessWidget {
  final Meal meal;
  const _MealTile({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_mealEmoji(meal.type), style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.typeLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            )),
                    Text(meal.name, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
            ],
          ),
          if (meal.prepMinutes != null || meal.servings != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (meal.prepMinutes != null) ...[
                  const Text('⏱️ ', style: TextStyle(fontSize: 14)),
                  Text('${meal.prepMinutes} dk',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
                if (meal.prepMinutes != null && meal.servings != null)
                  const Text('   ·   ', style: TextStyle(fontSize: 14)),
                if (meal.servings != null) ...[
                  const Text('👥 ', style: TextStyle(fontSize: 14)),
                  Text('${meal.servings} kişilik',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ],
          if (meal.ingredients.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Malzemeler',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: meal.ingredients
                  .map((i) => Chip(
                        label: Text(i),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text('Yapılışı',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (meal.steps.isNotEmpty)
            ...List.generate(meal.steps.length, (i) => _StepRow(index: i + 1, text: meal.steps[i]))
          else
            Text(meal.recipe, style: Theme.of(context).textTheme.bodyMedium),
          const Divider(height: 24),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
            child: Text('$index',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                )),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ShoppingTab extends StatefulWidget {
  final List<String> items;
  const _ShoppingTab({required this.items});
  @override
  State<_ShoppingTab> createState() => _ShoppingTabState();
}

class _ShoppingTabState extends State<_ShoppingTab> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(child: Text('Eksik malzeme yok — her şey evde!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.items.length,
      itemBuilder: (_, i) => CheckboxListTile(
        value: _checked.contains(i),
        onChanged: (v) => setState(() => v == true ? _checked.add(i) : _checked.remove(i)),
        title: Text(
          widget.items[i],
          style: _checked.contains(i)
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
