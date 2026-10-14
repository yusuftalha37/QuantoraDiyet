import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/api_client.dart';
import '../models/meal_plan.dart';
import '../demo_data.dart';
import '../theme.dart';
import '../widgets/cooking_loader.dart';
import '../widgets/shimmer.dart';
import '../widgets/anim.dart';
import 'plan_screen.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiClient.instance;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (context.read<AppState>().demo) {
      setState(() {
        _history = [];
        _loading = false;
      });
      return;
    }
    try {
      final history = await _api.get('/plans');
      setState(() => _history = (history['plans'] as List? ?? []).cast<Map<String, dynamic>>());
    } catch (_) {
      // leave UI usable even if load fails
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _suggest() async {
    final period = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _PeriodSheet(),
    );
    if (period == null || !mounted) return;
    final demo = context.read<AppState>().demo;

    // Eğlenceli "aşçı" bekleme ekranı; öneri hazırlanırken gösterilir.
    final outcome = await Navigator.of(context).push<LoaderOutcome>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CookingLoaderScreen(
          task: () async {
            if (demo) return DemoData.buildPlan('daily', period);
            final data = await _api.post('/plans', body: {'mode': 'daily', 'period': period});
            return MealPlan.fromResponse(data);
          },
        ),
      ),
    );
    if (!mounted || outcome == null) return;
    if (outcome.error != null || outcome.plan == null) {
      _showError('Öneri alınamadı. Bağlantıyı kontrol edin.');
      return;
    }
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlanScreen(plan: outcome.plan!)));
    if (!demo && mounted) _load();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openPlan(String id) async {
    try {
      final data = await _api.get('/plans/$id');
      if (!mounted) return;
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlanScreen(plan: MealPlan.fromResponse(data))));
    } catch (_) {
      _showError('Öneri açılamadı.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugün Ne Pişirsem?', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Hatırlatma',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Mutfağım',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Çıkış',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 4),
            const FadeSlideIn(child: _HeroCard()),
            const SizedBox(height: 18),
            // Ekranın ana aksiyonu. Tek dokunuş.
            FadeSlideIn(delayMs: 80, child: _BigSuggestButton(onTap: _suggest)),
            const SizedBox(height: 28),
            Text('Daha önce önerdiklerim',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_loading)
              const Shimmer(
                child: Column(
                  children: [
                    SkeletonListTileCard(),
                    SkeletonListTileCard(),
                    SkeletonListTileCard(),
                  ],
                ),
              ),
            if (_history.isEmpty && !_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      const Text('🥘', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text('Henüz öneri yok',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Yukarıdaki büyük yeşil düğmeye bas.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ...List.generate(_history.length, (i) {
              final p = _history[i];
              return FadeSlideIn(
                delayMs: 60 * i,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: const Text('🍽️', style: TextStyle(fontSize: 32)),
                    title: Text('${_periodLabel(p['period']?.toString())} önerileri',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.chevron_right, size: 28),
                    onTap: () => _openPlan(p['id'].toString()),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _periodLabel(String? period) => switch (period) {
        'daily' => 'Bugün',
        'weekly' => 'Bu hafta',
        'monthly' => 'Bu ay',
        _ => '',
      };
}

/// Üstteki modern "karşılama" kartı (koyu, yuvarlak — referans tasarımdaki gibi).
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E2823), AppTheme.heroDark],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Merhaba 👋',
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text('Bugün ne pişirelim?',
                    style: TextStyle(
                        color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                SizedBox(height: 8),
                Text('Alttaki düğmeye dokun, sana kolay yemekler önereyim.',
                    style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accent.withOpacity(0.5), width: 2),
            ),
            child: const Text('🍲', style: TextStyle(fontSize: 30)),
          ),
        ],
      ),
    );
  }
}

/// Ekranın ana aksiyonu: büyük, bariz, tek dokunuşluk yeşil düğme.
class _BigSuggestButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BigSuggestButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF08A42), Color(0xFFD85E22)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.40),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
          child: Column(
            children: [
              const Text('🍳', style: TextStyle(fontSize: 68)),
              const SizedBox(height: 14),
              Text('BUGÜN NE PİŞİREYİM?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 8),
              Text('Dokun, sana yemek önereyim',
                  style: TextStyle(color: scheme.onPrimary.withOpacity(0.9), fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Süre seçimi: üç büyük, tam genişlik düğme.
class _PeriodSheet extends StatelessWidget {
  const _PeriodSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Ne kadarlık öneri istersin?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _bigOption(context, '🍽️', 'Bugün için', 'daily'),
          const SizedBox(height: 14),
          _bigOption(context, '📅', 'Bu hafta için', 'weekly'),
          const SizedBox(height: 14),
          _bigOption(context, '🗓️', 'Bu ay için', 'monthly'),
        ],
      ),
    );
  }

  Widget _bigOption(BuildContext context, String emoji, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(value),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
