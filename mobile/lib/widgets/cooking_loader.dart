import 'dart:async';
import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../theme.dart';

class LoaderOutcome {
  final MealPlan? plan;
  final String? error;
  const LoaderOutcome({this.plan, this.error});
}

/// Öneri hazırlanırken gösterilen eğlenceli "aşçı" bekleme ekranı.
/// Verilen [task]'i çalıştırır, en az [minDuration] boyunca animasyonu
/// gösterir, sonra sonucu Navigator.pop ile [LoaderOutcome] olarak döndürür.
class CookingLoaderScreen extends StatefulWidget {
  final Future<MealPlan> Function() task;
  final Duration minDuration;
  const CookingLoaderScreen({
    super.key,
    required this.task,
    this.minDuration = const Duration(milliseconds: 2600),
  });

  @override
  State<CookingLoaderScreen> createState() => _CookingLoaderScreenState();
}

class _CookingLoaderScreenState extends State<CookingLoaderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _msgTimer;
  int _msgIndex = 0;
  int _emojiIndex = 0;

  // Yalnızca tek kod noktalı, her telefonda düzgün görünen emojiler
  // (birleşik "aşçı" emojileri bazı cihazlarda kutu/bozuk çıkabiliyor).
  static const _emojis = ['🍳', '🥘', '🍲', '🥗', '🍅', '🧅', '🥕', '🫑'];
  static const _messages = [
    'Tencere ocağa konuyor…',
    'Malzemeler doğranıyor…',
    'Soğanlar kavruluyor…',
    'Baharatlar ekleniyor…',
    'Tarifler karıştırılıyor…',
    'Nefis fikirler toplanıyor…',
    'Sofra hazırlanıyor…',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _msgTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (!mounted) return;
      setState(() {
        _msgIndex = (_msgIndex + 1) % _messages.length;
        _emojiIndex = (_emojiIndex + 1) % _emojis.length;
      });
    });
    _run();
  }

  Future<void> _run() async {
    final started = DateTime.now();
    LoaderOutcome outcome;
    try {
      final plan = await widget.task();
      outcome = LoaderOutcome(plan: plan);
    } catch (e) {
      outcome = LoaderOutcome(error: e.toString());
    }
    // Animasyonun en az minDuration kadar görünmesini sağla.
    final elapsed = DateTime.now().difference(started);
    final remaining = widget.minDuration - elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);
    if (mounted) Navigator.of(context).pop(outcome);
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.paper,
      body: SizedBox.expand(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dönen tabak + zıplayan emoji
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RotationTransition(
                        turns: _ctrl.drive(Tween(begin: 0.0, end: 0.04)),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.surface,
                            border: Border.all(color: c.hairline),
                          ),
                        ),
                      ),
                      ScaleTransition(
                        scale: _ctrl.drive(Tween(begin: 0.9, end: 1.1)
                            .chain(CurveTween(curve: Curves.easeInOut))),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (c, a) => FadeTransition(
                            opacity: a,
                            child: ScaleTransition(scale: a, child: c),
                          ),
                          child: Text(
                            _emojis[_emojiIndex],
                            key: ValueKey(_emojiIndex),
                            style: const TextStyle(fontSize: 72),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('Mutfakta çalışıyoruz',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    _messages[_msgIndex],
                    key: ValueKey(_msgIndex),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      backgroundColor: c.hairline,
                      valueColor: AlwaysStoppedAnimation(c.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
