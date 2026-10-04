import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/meal_plan.dart';

class PlanScreen extends StatelessWidget {
  final MealPlan plan;
  const PlanScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final singleDay = plan.days.length == 1;
    return Scaffold(
      appBar: AppBar(title: const Text('Yemek Önerilerin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ekranın ne olduğunu basitçe anlatan kutu.
          _InfoBox(singleDay: singleDay),
          const SizedBox(height: 14),

          // Alışveriş listesi büyük düğme.
          _ShoppingButton(items: plan.shoppingList),
          const SizedBox(height: 20),

          if (singleDay)
            // Tek gün: her şeyi açık göster.
            ...plan.days.first.meals.map((m) => _MealCard(meal: m))
          else
            // Çok gün: her gün için dokunup açılan kart.
            ...plan.days.map((d) => _DayCard(day: d)),
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
                  ? 'İşte bugün pişirebileceğin yemekler. Her yemeğin altında '
                      'MALZEMELER ve ADIM ADIM yapılışı yazıyor.'
                  : 'Aşağıda her gün için yemekler var. Bir güne DOKUN, o günün '
                      'yemekleri açılsın. Her yemeğin malzemesi ve yapılışı yazıyor.',
              style: TextStyle(fontSize: 16, color: scheme.onSecondaryContainer, height: 1.3),
            ),
          ),
        ],
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

// Birbiriyle uyumlu, sıcak-soğuk dengeli palet.
Color _mealColor(String type, ColorScheme s) => switch (type) {
      'breakfast' => const Color(0xFFE8A317), // bal sarısı
      'lunch' => const Color(0xFF2F9E5B), // taze yeşil
      'dinner' => const Color(0xFFD86A3C), // terakota
      'snack' => const Color(0xFF2B9E8D), // deniz yeşili
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
  final DayPlan day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        initiallyExpanded: day.day == 1,
        leading: const Text('📅', style: TextStyle(fontSize: 28)),
        title: Text(day.label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text('👉 Dokun, ${day.meals.length} yemeği gör',
            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: day.meals.map((m) => _MealCard(meal: m)).toList(),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _mealColor(meal.type, scheme);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Renkli başlık: hangi öğün + yemek adı.
          Container(
            width: double.infinity,
            color: color,
            padding: const EdgeInsets.all(14),
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meal.prepMinutes != null || meal.servings != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        if (meal.prepMinutes != null)
                          _pill(context, '⏱️ ${meal.prepMinutes} dakika'),
                        if (meal.servings != null) ...[
                          const SizedBox(width: 8),
                          _pill(context, '👥 ${meal.servings} kişilik'),
                        ],
                      ],
                    ),
                  ),

                // MALZEMELER
                Row(children: [
                  const Text('🧺 ', style: TextStyle(fontSize: 18)),
                  Text('NELER GEREKİYOR?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      )),
                ]),
                const SizedBox(height: 6),
                ...meal.ingredients.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  ', style: TextStyle(fontSize: 18)),
                          Expanded(child: Text(i, style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    )),

                const SizedBox(height: 14),
                // YAPILIŞI
                Row(children: [
                  const Text('👨‍🍳 ', style: TextStyle(fontSize: 18)),
                  Text('NASIL YAPILIR?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      )),
                ]),
                const SizedBox(height: 8),
                if (meal.steps.isNotEmpty)
                  ...List.generate(meal.steps.length,
                      (i) => _StepRow(index: i + 1, text: meal.steps[i], color: color))
                else
                  Text(meal.recipe, style: const TextStyle(fontSize: 16, height: 1.35)),
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
          // Açıklama + ilerleme
          Container(
            width: double.infinity,
            color: scheme.primaryContainer,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🛒 Markete gidince bunları al',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    )),
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    )),
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
                  onTap: () =>
                      setState(() => checked ? _checked.remove(i) : _checked.add(i)),
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
