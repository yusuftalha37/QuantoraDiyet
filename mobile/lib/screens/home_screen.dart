import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/api_client.dart';
import '../models/meal_plan.dart';
import 'plan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiClient.instance;
  Map<String, dynamic>? _targets;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final targets = await _api.get('/targets');
      final history = await _api.get('/plans');
      setState(() {
        _targets = targets;
        _history = (history['plans'] as List? ?? []).cast<Map<String, dynamic>>();
      });
    } catch (_) {
      // leave UI usable even if load fails
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    final choice = await showModalBottomSheet<_GenChoice>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _GenerateSheet(),
    );
    if (choice == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final data = await _api.post('/plans', body: {'mode': choice.mode, 'period': choice.period});
      if (!mounted) return;
      Navigator.of(context).pop(); // close loader
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
      _showError('Plan oluşturulamadı. Bağlantıyı kontrol edin.');
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
      _showError('Plan açılamadı.');
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
            tooltip: 'Çıkış',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generate,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Plan oluştur'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_targets != null) _TargetsCard(targets: _targets!),
            const SizedBox(height: 20),
            Text('Planlarım', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_history.isEmpty && !_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Henüz plan yok. "Plan oluştur"a dokun.')),
              ),
            ..._history.map((p) => Card(
                  child: ListTile(
                    leading: Icon(p['mode'] == 'diet' ? Icons.monitor_heart_outlined : Icons.restaurant),
                    title: Text(_periodLabel(p['period']?.toString()) +
                        (p['mode'] == 'diet' ? ' diyet planı' : ' yemek planı')),
                    subtitle: Text(p['summary']?.toString() ?? '',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Text('${p['targetCalories'] ?? ''} kcal'),
                    onTap: () => _openPlan(p['id'].toString()),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _periodLabel(String? period) => switch (period) {
        'daily' => 'Günlük',
        'weekly' => 'Haftalık',
        'monthly' => 'Aylık',
        _ => '',
      };
}

class _TargetsCard extends StatelessWidget {
  final Map<String, dynamic> targets;
  const _TargetsCard({required this.targets});

  @override
  Widget build(BuildContext context) {
    final macros = targets['macros'] as Map<String, dynamic>? ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Günlük hedefin', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stat(context, '${targets['targetCalories'] ?? '-'}', 'kcal'),
                _stat(context, '${macros['proteinG'] ?? '-'} g', 'Protein'),
                _stat(context, '${macros['carbsG'] ?? '-'} g', 'Karbonhidrat'),
                _stat(context, '${macros['fatG'] ?? '-'} g', 'Yağ'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) => Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _GenChoice {
  final String mode;
  final String period;
  _GenChoice(this.mode, this.period);
}

class _GenerateSheet extends StatefulWidget {
  const _GenerateSheet();
  @override
  State<_GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends State<_GenerateSheet> {
  String _mode = 'diet';
  String _period = 'weekly';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ne hazırlayalım?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          const Text('Tür'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'diet', label: Text('Diyet'), icon: Icon(Icons.monitor_heart_outlined)),
              ButtonSegment(value: 'daily', label: Text('Günlük yemek'), icon: Icon(Icons.restaurant)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 20),
          const Text('Süre'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'daily', label: Text('Günlük')),
              ButtonSegment(value: 'weekly', label: Text('Haftalık')),
              ButtonSegment(value: 'monthly', label: Text('Aylık')),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() => _period = s.first),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_GenChoice(_mode, _period)),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}
