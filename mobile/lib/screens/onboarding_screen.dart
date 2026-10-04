import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/profile.dart';
import '../services/api_client.dart';
import '../pantry_catalog.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _saving = false;
  String? _error;

  // Mutfak tercihleri
  String _diet = 'omnivore';
  final _allergy = TextEditingController();
  final List<String> _allergies = [];

  // Evdeki malzemeler
  final _pantryInput = TextEditingController();
  final List<String> _pantry = [];

  @override
  void dispose() {
    _allergy.dispose();
    _pantryInput.dispose();
    super.dispose();
  }

  /// "Evinde ne var?" bölümünü atla: ortalama ev + mevsim ürünlerini kullan.
  Future<void> _skip() async {
    setState(() {
      _pantry
        ..clear()
        ..addAll(seasonalDefaultPantry());
    });
    await _finish();
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final state = context.read<AppState>();
      // Diyet/kalori işi kaldırıldı; vücut alanları arka planda varsayılan.
      final profile = Profile(
        sex: 'other',
        birthYear: 1990,
        heightCm: 170,
        weightKg: 70,
        activityLevel: 'moderate',
        goal: 'maintain',
        dietType: _diet,
        allergies: _allergies,
        dislikedFoods: const [],
      );
      await state.saveProfile(profile);
      await state.savePantry(_pantry.map((e) => {'name': e}).toList());
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Kaydedilemedi. Bağlantıyı kontrol edin.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoş geldin')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const Center(child: Text('👋', style: TextStyle(fontSize: 64))),
            const SizedBox(height: 12),
            Text('Sana yemek önerelim!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'Hiçbir şey doldurmana gerek yok. Sadece başla; evinde genelde '
              'bulunan malzemelere ve mevsime göre öneri veririz.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),

            // ANA YOL: tek dokunuş.
            FilledButton(
              onPressed: _saving ? null : _skip,
              child: _saving
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('🍳  HADİ BAŞLA'),
            ),
            const SizedBox(height: 20),

            // İSTEĞE BAĞLI: kendin ayarla.
            Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                shape: const Border(),
                leading: const Text('⚙️', style: TextStyle(fontSize: 26)),
                title: const Text('İstersen kendin seç',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('(isteğe bağlı)'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _dropdown('Beslenme tercihi', _diet, const {
                    'omnivore': 'Fark etmez', 'vegetarian': 'Vejetaryen', 'vegan': 'Vegan',
                    'pescatarian': 'Pesketaryen', 'halal': 'Helal', 'glutenfree': 'Glutensiz',
                  }, (v) => setState(() => _diet = v)),
                  const SizedBox(height: 8),
                  _chipInput('Yemediğin / alerjin (örn. fındık)', _allergy, _allergies),
                  const SizedBox(height: 16),
                  Text('Evinde neler var?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Seçili: ${_pantry.length} malzeme',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  ...kPantryCatalog.map(_categorySection),
                  const SizedBox(height: 8),
                  _chipInput('Listede yok mu? Elle ekle', _pantryInput, _pantry),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _finish,
                    child: const Text('Kaydet ve başla'),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categorySection(PantryCategory cat) {
    final selectedInCat = cat.items.where(_pantry.contains).length;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        shape: const Border(),
        leading: Icon(cat.icon),
        title: Text(cat.title),
        subtitle: selectedInCat > 0 ? Text('$selectedInCat seçili') : null,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: cat.items.map((item) {
              final selected = _pantry.contains(item);
              return FilterChip(
                label: Text(item),
                selected: selected,
                onSelected: (on) => setState(() {
                  if (on) {
                    if (!_pantry.contains(item)) _pantry.add(item);
                  } else {
                    _pantry.remove(item);
                  }
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, Map<String, String> options, ValueChanged<String> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(labelText: label),
          items: options.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => onChanged(v ?? value),
        ),
      );

  Widget _chipInput(String hint, TextEditingController c, List<String> target) {
    void add() {
      final v = c.text.trim();
      if (v.isNotEmpty && !target.contains(v)) {
        setState(() => target.add(v));
      }
      c.clear();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: c,
                decoration: InputDecoration(labelText: hint),
                onSubmitted: (_) => add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(onPressed: add, icon: const Icon(Icons.add)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: target
              .map((item) => Chip(
                    label: Text(item),
                    onDeleted: () => setState(() => target.remove(item)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
