import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'secure_store.dart';

/// Her gün belirli saatte "Akşam ne pişireceğine karar verdin mi?" hatırlatması.
class ReminderService {
  ReminderService._();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _id = 1001;

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));
      // Daha önce açıldıysa yeniden planla.
      final s = SecureStore.instance;
      if (await s.reminderEnabled()) {
        final (h, m) = await s.reminderTime();
        await _schedule(h, m);
      }
    } catch (_) {
      // bildirim desteklenmiyorsa sessiz geç
    }
  }

  static Future<bool> enable(int hour, int minute) async {
    try {
      final android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission() ?? true;
      if (!granted) return false;
      await _schedule(hour, minute);
      await SecureStore.instance.setReminder(true, hour, minute);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> disable() async {
    try {
      await _plugin.cancel(_id);
    } catch (_) {}
    await SecureStore.instance.setReminder(false, null, null);
  }

  static Future<void> _schedule(int hour, int minute) async {
    await _plugin.zonedSchedule(
      _id,
      'Bugün Ne Pişirsem?',
      'Akşam ne pişireceğine karar verdin mi? 🍲 Dokun, öneri alalım.',
      _nextInstance(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Günlük Hatırlatma',
          channelDescription: 'Her gün yemek hatırlatması',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // her gün tekrar
    );
  }

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }
}
