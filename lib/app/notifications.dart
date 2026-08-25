import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Opt-in local reminders. Nothing is scheduled unless the user turns a
/// toggle on in Settings.
class Notifications {
  Notifications._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _weeklyId = 1;
  static const _dailyId = 2;
  static const _channel = AndroidNotificationDetails(
    'photorank_reminders',
    'Reminders',
    channelDescription: 'Weekly recap and daily hand reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('notifications unavailable: $e');
    }
  }

  static Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, badge: false, sound: false) ?? false;
    return false;
  }

  static Future<void> setWeeklyRecap(bool on) async {
    await init();
    if (!_ready) return;
    if (!on) return _plugin.cancel(id: _weeklyId);
    await _plugin.periodicallyShow(
      id: _weeklyId,
      title: 'Your week in photos is ready',
      body: 'Open PhotoRank to see what climbed, what settled, and your top 9.',
      repeatInterval: RepeatInterval.weekly,
      notificationDetails: const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> setDailyReminder(bool on) async {
    await init();
    if (!_ready) return;
    if (!on) return _plugin.cancel(id: _dailyId);
    await _plugin.periodicallyShow(
      id: _dailyId,
      title: 'A few photos await your verdict',
      body: 'One quick hand keeps your favourites sharp.',
      repeatInterval: RepeatInterval.daily,
      notificationDetails: const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
