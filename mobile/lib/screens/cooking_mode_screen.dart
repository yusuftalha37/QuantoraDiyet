import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../services/tts_service.dart';

/// Adım adım pişirme modu: her ekranda tek büyük adım, İleri/Geri ve sesli okuma.
class CookingModeScreen extends StatefulWidget {
  final Meal meal;
  const CookingModeScreen({super.key, required this.meal});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  int _i = 0;

  List<String> get _steps =>
      widget.meal.steps.isNotEmpty ? widget.meal.steps : [widget.meal.recipe];

  @override
  void dispose() {
    TtsService.stop();
    super.dispose();
  }

  void _speak() => TtsService.speak(_steps[_i]);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _steps.length;
    final last = _i == total - 1;

    return Scaffold(
      appBar: AppBar(title: Text(widget.meal.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // İlerleme
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: (_i + 1) / total, minHeight: 10),
              ),
              const SizedBox(height: 10),
              Text('Adım ${_i + 1} / $total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.primary)),
              const SizedBox(height: 20),

              // Büyük adım metni
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      _steps[_i],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, height: 1.4),
                    ),
                  ),
                ),
              ),

              // Sesli oku
              OutlinedButton.icon(
                onPressed: _speak,
                icon: const Text('📢', style: TextStyle(fontSize: 22)),
                label: const Text('Sesli oku'),
              ),
              const SizedBox(height: 12),

              // İleri / Geri
              Row(
                children: [
                  if (_i > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _i--),
                        child: const FittedBox(child: Text('← Geri')),
                      ),
                    ),
                  if (_i > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        if (last) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() => _i++);
                        }
                      },
                      child: FittedBox(child: Text(last ? '🎉 Bitti!' : 'İleri →')),
                    ),
                  ),
                ],
              ),
              if (last)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Afiyet olsun! 🍽️',
                      style: TextStyle(fontSize: 16, color: scheme.primary)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
