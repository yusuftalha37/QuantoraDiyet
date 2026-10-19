import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/meal_plan.dart';
import '../services/tts_service.dart';
import '../theme.dart';

/// Adım adım pişirme: her ekranda tek büyük adım, İleri/Geri ve sesli okuma.
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
    final c = AppColors.of(context);
    final total = _steps.length;
    final last = _i == total - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meal.name, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // İlerleme: ince çizgi + "Adım x / y"
              Row(
                children: List.generate(total, (k) {
                  final filled = k <= _i;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: k == total - 1 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: filled ? c.accent : c.hairline,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Text('Adım ${_i + 1} / $total',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.inkMuted, letterSpacing: 0.3)),
              const SizedBox(height: 20),

              // Büyük adım metni
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SingleChildScrollView(
                    child: Text(
                      _steps[_i],
                      style: const TextStyle(fontSize: 25, height: 1.45, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),

              TextButton.icon(
                onPressed: _speak,
                icon: const Icon(Symbols.volume_up, size: 20),
                label: const Text('Sesli oku'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (_i > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _i--),
                        child: const Text('Geri'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
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
                      child: Text(last ? 'Bitir' : 'İleri'),
                    ),
                  ),
                ],
              ),
              if (last)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Afiyet olsun!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: c.inkMuted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
