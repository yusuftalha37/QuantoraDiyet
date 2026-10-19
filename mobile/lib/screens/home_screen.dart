import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/api_client.dart';
import '../models/meal_plan.dart';
import '../demo_data.dart';
import '../theme.dart';
import '../widgets/cooking_loader.dart';
import '../widgets/shimmer.dart';
import '../widgets/ui.dart';
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
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
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
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _suggest() async {
    final period = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.of(context).paper,
      builder: (_) => const _PeriodSheet(),
    );
    if (period == null || !mounted) return;
    final demo = context.read<AppState>().demo;

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
      _showError('Öneri alınamadı. Bağlantını kontrol et.');
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
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugün Ne Pişirsem?', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Hatırlatma',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Mutfağım',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Çıkış',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AppState>().logout(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text('Merhaba 👋', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Bugün ne pişirelim?', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),

            // Tek net birincil eylem.
            FilledButton(
              onPressed: _suggest,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.restaurant_rounded, size: 22),
                  SizedBox(width: 10),
                  Text('Bana yemek öner'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Evinde genelde bulunan malzemelere göre öneri alırsın.',
                style: Theme.of(context).textTheme.bodyMedium),

            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SectionLabel('Önerilerim'),
                const Spacer(),
                if (!_loading && _history.isNotEmpty)
                  Text('${_history.length}',
                      style: TextStyle(color: c.inkMuted, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),

            if (_loading)
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Shimmer(
                  child: Column(
                    children: [
                      SkeletonListTileCard(),
                      Divider(height: 1),
                      SkeletonListTileCard(),
                    ],
                  ),
                ),
              )
            else if (_failed)
              _StateMessage(
                icon: Icons.wifi_off_rounded,
                title: 'Önerilerin yüklenemedi',
                detail: 'Bağlantını kontrol edip tekrar dene.',
                actionLabel: 'Tekrar dene',
                onAction: _load,
              )
            else if (_history.isEmpty)
              _StateMessage(
                icon: Icons.outdoor_grill_rounded,
                title: 'Henüz öneri yok',
                detail: 'Yukarıdaki düğmeye dokun, ilk önerini alalım.',
              )
            else
              _HistoryList(items: _history, onOpen: _openPlan, periodLabel: _periodLabel),
          ],
        ),
      ),
    );
  }

  String _periodLabel(String? period) => switch (period) {
        'daily' => 'Bugün',
        'weekly' => 'Bu hafta',
        'monthly' => 'Bu ay',
        _ => 'Öneri',
      };
}

/// Geçmiş öneriler — tek kart içinde ince ayraçlı sade satırlar.
class _HistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(String id) onOpen;
  final String Function(String?) periodLabel;
  const _HistoryList({required this.items, required this.onOpen, required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.hairline),
            InkWell(
              onTap: () => onOpen(items[i]['id'].toString()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.restaurant_menu_rounded, size: 22, color: c.inkMuted),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('${periodLabel(items[i]['period']?.toString())} önerileri',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 24, color: c.inkMuted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Boş / hata durumları için sade, ortak mesaj bloğu.
class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.detail,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 34, color: c.inkMuted),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Süre seçimi — sade, tam-genişlik satırlar (bugün / bu hafta / bu ay).
class _PeriodSheet extends StatelessWidget {
  const _PeriodSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ne kadarlık öneri istersin?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _option(context, Icons.wb_sunny_outlined, 'Bugün', 'Tek günlük', 'daily'),
            const SizedBox(height: 10),
            _option(context, Icons.calendar_view_week_rounded, 'Bu hafta', '7 günlük', 'weekly'),
            const SizedBox(height: 10),
            _option(context, Icons.calendar_month_rounded, 'Bu ay', '30 günlük', 'monthly'),
          ],
        ),
      ),
    );
  }

  Widget _option(BuildContext context, IconData icon, String title, String sub, String value) {
    final c = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => Navigator.of(context).pop(value),
      child: Row(
        children: [
          Icon(icon, size: 24, color: c.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                Text(sub, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.inkMuted),
        ],
      ),
    );
  }
}
