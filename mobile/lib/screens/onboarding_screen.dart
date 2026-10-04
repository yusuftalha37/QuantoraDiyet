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

  // Vücut bilgileri
  String _sex = 'female';
  final _birthYear = TextEditingController(text: '1995');
  final _height = TextEditingController(text: '170');
  final _weight = TextEditingController(text: '70');

  // Tercihler
  String _activity = 'moderate';
  String _goal = 'lose';
  String _diet = 'omnivore';
  final _allergy = TextEditingController();
  final List<String> _allergies = [];

  // Evdeki malzemeler
  final _pantryInput = TextEditingController();
  final List<String> _pantry = [];

  @override
  void dispose() {
    _birthYear.dispose();
    _height.dispose();
    _weight.dispose();
    _allergy.dispose();
    _pantryInput.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final state = context.read<AppState>();
      final profile = Profile(
        sex: _sex,
        birthYear: int.tryParse(_birthYear.text) ?? 1995,
        heightCm: double.tryParse(_height.text) ?? 170,
        weightKg: double.tryParse(_weight.text) ?? 70,
        activityLevel: _activity,
        goal: _goal,
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
      appBar: AppBar(title: const Text('Hoş geldin! Seni tanıyalım')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _sectionTitle(context, '1. Vücut bilgileri', Icons.person_outline),
            _dropdown('Cinsiyet', _sex, const {
              'female': 'Kadın', 'male': 'Erkek', 'other': 'Belirtmek istemiyorum',
            }, (v) => setState(() => _sex = v)),
            _numField('Doğum yılı', _birthYear),
            _numField('Boy (cm)', _height),
            _numField('Kilo (kg)', _weight),

            const SizedBox(height: 24),
            _sectionTitle(context, '2. Tercihler', Icons.tune),
            _dropdown('Aktivite düzeyi', _activity, const {
              'sedentary': 'Hareketsiz', 'light': 'Az hareketli', 'moderate': 'Orta',
              'active': 'Aktif', 'very_active': 'Çok aktif',
            }, (v) => setState(() => _activity = v)),
            _dropdown('Hedef', _goal, const {
              'lose': 'Kilo vermek', 'maintain': 'Korumak', 'gain': 'Kilo almak',
            }, (v) => setState(() => _goal = v)),
            _dropdown('Diyet türü', _diet, const {
              'omnivore': 'Her şey', 'vegetarian': 'Vejetaryen', 'vegan': 'Vegan',
              'pescatarian': 'Pesketaryen', 'keto': 'Keto', 'mediterranean': 'Akdeniz',
              'halal': 'Helal', 'glutenfree': 'Glutensiz',
            }, (v) => setState(() => _diet = v)),
            const SizedBox(height: 8),
            _chipInput('Alerji ekle (örn. fındık)', _allergy, _allergies),

            const SizedBox(height: 24),
            _sectionTitle(context, '3. Evinde neler var?', Icons.kitchen),
            const Text(
              'Evdeki malzemeleri kategorilerden seç. Planların önce bunlarla '
              'hazırlanır; listede olmayanı aşağıdan elle ekleyebilirsin.',
            ),
            const SizedBox(height: 4),
            Text('Seçili: ${_pantry.length} malzeme',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            ...kPantryCatalog.map(_categorySection),
            const SizedBox(height: 8),
            _chipInput('Listede yok mu? Elle ekle', _pantryInput, _pantry),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _finish,
              icon: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet ve başla'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(text, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );

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

  Widget _numField(String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
      );

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
