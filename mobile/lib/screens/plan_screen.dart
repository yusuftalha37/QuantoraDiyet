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
      child: ExpansionTile(
        shape: const Border(),
        title: Text(day.label, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('${day.meals.length} öğün'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: day.meals.map((m) => _MealTile(meal: m)).toList(),
      ),
    );
  }
}

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
          Text('${meal.typeLabel}: ${meal.name}',
              style: Theme.of(context).textTheme.titleSmall),
          if (meal.ingredients.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: -6,
              children: meal.ingredients
                  .map((i) => Chip(label: Text(i), visualDensity: VisualDensity.compact))
                  .toList(),
            ),
          ],
          const SizedBox(height: 6),
          Text(meal.recipe, style: Theme.of(context).textTheme.bodyMedium),
          const Divider(height: 20),
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
