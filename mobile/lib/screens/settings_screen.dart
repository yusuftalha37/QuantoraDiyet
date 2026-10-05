import 'package:flutter/material.dart';
import '../services/reminder_service.dart';
import '../services/secure_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _on = false;
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = SecureStore.instance;
    final on = await s.reminderEnabled();
    final (h, m) = await s.reminderTime();
    setState(() {
      _on = on;
      _time = TimeOfDay(hour: h, minute: m);
      _loading = false;
    });
  }

  Future<void> _toggle(bool v) async {
    if (v) {
      final ok = await ReminderService.enable(_time.hour, _time.minute);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Bildirim izni verilmedi. Ayarlardan izin verebilirsin.')));
        return;
      }
    } else {
      await ReminderService.disable();
    }
    setState(() => _on = v);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() => _time = picked);
    if (_on) await ReminderService.enable(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('🔔', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Günlük Hatırlatma',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Her gün belirlediğin saatte "Akşam ne pişireceğine karar '
                  'verdin mi?" diye hatırlatalım mı?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: SwitchListTile(
                    value: _on,
                    onChanged: _toggle,
                    title: const Text('Hatırlatma açık',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    secondary: const Text('⏰', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    enabled: _on,
                    leading: const Text('🕐', style: TextStyle(fontSize: 28)),
                    title: const Text('Saat', style: TextStyle(fontSize: 18)),
                    trailing: Text(
                      _time.format(context),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _on ? scheme.primary : scheme.outline,
                      ),
                    ),
                    onTap: _on ? _pickTime : null,
                  ),
                ),
              ],
            ),
    );
  }
}
