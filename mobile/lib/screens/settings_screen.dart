import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../services/reminder_service.dart';
import '../services/secure_store.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';

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

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabımı sil'),
        content: const Text(
          'Hesabın ve tüm verilerin (profil, malzemeler, öneriler) kalıcı olarak '
          'silinecek. Bu işlem geri alınamaz. Emin misin?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AppState>().deleteAccount();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Hesap silinemedi. Bağlantıyı kontrol et.')));
      }
    }
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
                Center(child: Icon(Symbols.notifications_active, size: 40, color: scheme.primary)),
                const SizedBox(height: 10),
                Text('Günlük Hatırlatma',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
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
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    secondary: Icon(Symbols.alarm, color: scheme.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    enabled: _on,
                    leading: const Icon(Symbols.schedule),
                    title: const Text('Saat', style: TextStyle(fontSize: 17)),
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

                // Hesap silme — yalnızca gerçek hesapla girişte (demo değil).
                if (!context.watch<AppState>().demo) ...[
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error),
                      minimumSize: const Size.fromHeight(54),
                    ),
                    onPressed: _deleteAccount,
                    icon: const Icon(Symbols.delete),
                    label: const Text('Hesabımı sil'),
                  ),
                ],
              ],
            ),
    );
  }
}
