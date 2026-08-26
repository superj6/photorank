import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Opt-in local reminders. Nothing is scheduled unless the user turns a
/// toggle on in Settings.
class Notifications {
  Notifications._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _weeklyId = 1;
  static const _dailyId = 2;
  static const _arenaId = 3;
  static bool _tzReady = false;
  static const _channel = AndroidNotificationDetails(
    'photorank_reminders',
    'Reminders',
    channelDescription: 'Weekly recap and daily hand reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  /// Scheduled notifications exist on Android/iOS; Linux only shows immediately.
  static bool get _canSchedule => !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  static Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
          linux: LinuxInitializationSettings(defaultActionName: 'Open'),
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
    return _plugin.resolvePlatformSpecificImplementation<LinuxFlutterLocalNotificationsPlugin>() != null;
  }

  static Future<void> setWeeklyRecap(bool on) async {
    await init();
    if (!_ready) return;
    if (!on) return _plugin.cancel(id: _weeklyId);
    if (!_canSchedule) return;
    await _plugin.periodicallyShow(
      id: _weeklyId,
      title: 'Your week in photos is ready',
      body: 'Open PhotoRank to see what climbed, what settled, and your top 9.',
      repeatInterval: RepeatInterval.weekly,
      notificationDetails: const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> _initTz() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    _tzReady = true;
  }

  /// Daily "enter today's arena" at [hour] local time. Pass [skipToday] when
  /// the user has already entered, so the next one fires tomorrow.
  static Future<void> setArenaReminder(bool on, {int hour = 18, bool skipToday = false}) async {
    await init();
    if (!_ready) return;
    await _plugin.cancel(id: _arenaId);
    if (!on || !_canSchedule) return;
    await _initTz();
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (skipToday || !at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: _arenaId,
      title: 'Today\'s arena is open',
      body: 'Enter a photo from today, rate a set, and see where it lands.',
      scheduledDate: at,
      notificationDetails: const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> setDailyReminder(bool on) async {
    await init();
    if (!_ready) return;
    if (!on) return _plugin.cancel(id: _dailyId);
    if (!_canSchedule) return;
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
