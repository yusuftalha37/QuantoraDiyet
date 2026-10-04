import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/api_client.dart';
import '../models/meal_plan.dart';
import '../demo_data.dart';
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

    // Demo modu: ağ çağrısı yok, öneri yerel örnek veriden üretilir.
    if (context.read<AppState>().demo) {
      final plan = DemoData.buildPlan('daily', period);
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlanScreen(plan: plan)));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final data = await _api.post('/plans', body: {'mode': 'daily', 'period': period});
      if (!mounted) return;
      Navigator.of(context).pop();
      final plan = MealPlan.fromResponse(data);
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlanScreen(plan: plan)));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showError('Öneri alınamadı. Bağlantıyı kontrol edin.');
    }
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Henüz öneri yok. "Yemek öner"e dokun.')),
              ),
            ..._history.map((p) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.restaurant),
                    title: Text('${_periodLabel(p['period']?.toString())} önerileri'),
                    subtitle: Text(p['summary']?.toString() ?? '',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
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
    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.soup_kitchen, size: 40, color: scheme.onPrimaryContainer),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bugün ne pişireyim?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: scheme.onPrimaryContainer,
                            )),
                    const SizedBox(height: 4),
                    Text('Evindeki malzemelere göre öneri al',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                            )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
            ],
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
