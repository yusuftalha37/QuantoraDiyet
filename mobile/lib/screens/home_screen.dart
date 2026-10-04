import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/api_client.dart';
import '../models/meal_plan.dart';
import '../demo_data.dart';
import '../widgets/cooking_loader.dart';
import 'plan_screen.dart';
import 'onboarding_screen.dart';

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
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Merhaba, ${state.displayName ?? ''}'),
        actions: [
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _suggest,
        icon: const Icon(Icons.restaurant_menu),
        label: const Text('Yemek öner'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (state.demo)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demo modu: öneriler örnektir, backend’e bağlanılmaz.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            _HeroCard(onTap: _suggest),
            const SizedBox(height: 20),
            Text('Önceki önerilerim', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_history.isEmpty && !_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      const Text('🥘', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('Henüz öneri yok',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('"Yemek öner"e dokun, mutfağa koyulalım!',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ..._history.map((p) => Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: const Text('🍽️', style: TextStyle(fontSize: 20)),
                    ),
                    title: Text('${_periodLabel(p['period']?.toString())} önerileri'),
                    subtitle: Text(p['summary']?.toString() ?? '',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openPlan(p['id'].toString()),
                  ),
                )),
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

class _HeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.tertiary],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('🍳', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bugün ne pişireyim?',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              )),
                      const SizedBox(height: 4),
                      Text('Evindeki malzemelere göre öneri al',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onPrimary.withOpacity(0.9),
                              )),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: scheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodSheet extends StatefulWidget {
  const _PeriodSheet();
  @override
  State<_PeriodSheet> createState() => _PeriodSheetState();
}

class _PeriodSheetState extends State<_PeriodSheet> {
  String _period = 'daily';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ne kadarlık öneri?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'daily', label: Text('Bugün')),
              ButtonSegment(value: 'weekly', label: Text('Bu hafta')),
              ButtonSegment(value: 'monthly', label: Text('Bu ay')),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() => _period = s.first),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_period),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Öner'),
          ),
        ],
      ),
    );
  }
}
