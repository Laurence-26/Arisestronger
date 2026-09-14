import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/quotes.dart';

/// Real, scheduled local notifications:
///  • Daily morning reminder carrying the day's motivation quote.
///  • Evening "quest incomplete" Solo Leveling nudge.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const int _morningId = 1001;
  static const int _eveningId = 1002;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'daily_quest',
    'AriseStronger',
    channelDescription: 'Daily quest reminders and motivation',
    importance: Importance.max,
    priority: Priority.high,
    styleInformation: BigTextStyleInformation(''),
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to UTC if the platform timezone can't be resolved.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
    _ready = true;
  }

  /// Ask the OS for permission to post notifications (Android 13+ and iOS).
  Future<bool> requestPermissions() async {
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
            alert: true, badge: true, sound: true);
        return granted ?? false;
      }
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
    return false;
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _schedule(
    int id,
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOf(hour, minute),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
    } catch (e) {
      debugPrint('Notification schedule failed: $e');
    }
  }

  /// (Re)schedule the recurring daily reminders. Call after login and whenever
  /// the user changes their reminder time.
  Future<void> scheduleDailyReminders({
    required int hour,
    required int minute,
  }) async {
    if (!_ready) await init();
    await _safeCancel(_morningId);
    await _safeCancel(_eveningId);

    final q = quoteForDay(DateTime.now());
    await _schedule(
      _morningId,
      hour,
      minute,
      '◈ ARISE, HUNTER ◈',
      '"${q.text}" — ${q.author}',
    );

    await _schedule(
      _eveningId,
      20,
      30,
      '◈ PENALTY WARNING ◈',
      'Your daily quest isn\'t complete. Finish it before midnight or the '
          'Penalty Zone will claim your progress. Don\'t break the chain, Hunter.',
    );
  }

  /// Immediate notification (used for testing / instant feedback).
  Future<void> showNow(String title, String body) async {
    if (!_ready) await init();
    try {
      await _plugin.show(9000, title, body, _details);
    } catch (e) {
      debugPrint('Notification show failed: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Notification cancelAll failed: $e');
    }
  }

  /// Cancel must never take the app down. Release R8 can still throw
  /// "Missing type parameter" on a stale scheduled-notification cache.
  Future<void> _safeCancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('Notification cancel($id) failed: $e');
    }
  }
}
