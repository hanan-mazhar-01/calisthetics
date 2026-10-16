import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the daily "time to train" reminder on the device. Nothing is
/// sent to a server: the OS fires the notification locally.
abstract class ReminderService {
  /// Asks for notification permission; true when reminders can be shown.
  Future<bool> requestPermission();

  /// Whether the OS currently lets this app show notifications.
  Future<bool> isPermitted();

  /// Replaces every reminder with one per [weekdays] ([DateTime.weekday]
  /// values, 1 = Monday) at [time], repeating weekly.
  Future<void> schedule({required TimeOfDay time, required Set<int> weekdays});

  Future<void> cancelAll();
}

/// Never touches the platform. Used where no OS is available (tests).
class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> isPermitted() async => false;

  @override
  Future<void> schedule({
    required TimeOfDay time,
    required Set<int> weekdays,
  }) async {}

  @override
  Future<void> cancelAll() async {}
}

/// [ReminderService] on top of flutter_local_notifications. Every platform
/// call is guarded: a failure to remind must never break the app.
class LocalReminderService implements ReminderService {
  LocalReminderService();

  static const _channelId = 'daily_reminder';
  static const _idBase = 4100;

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  Future<bool> _init() => _ready ??= _initOnce();

  Future<bool> _initOnce() async {
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Reminders unavailable: $e');
      return false;
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> isPermitted() async {
    if (!await _init()) return false;
    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!await _init()) return false;
    try {
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> schedule({
    required TimeOfDay time,
    required Set<int> weekdays,
  }) async {
    if (!await _init()) return;
    try {
      await cancelAll();
      for (final weekday in weekdays) {
        await _plugin.zonedSchedule(
          id: _idBase + weekday,
          title: "Time to train",
          body: "Today's session is ready when you are.",
          scheduledDate: _next(weekday, time),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              'Training reminders',
              channelDescription: 'A reminder on the days your plan trains.',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
          // Inexact: no special alarm permission, and a few minutes of drift
          // is fine for a "time to train" nudge.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e) {
      debugPrint('Could not schedule reminders: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!await _init()) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// The next [weekday] (1 = Monday) at [time], strictly in the future.
  static tz.TZDateTime _next(int weekday, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    // Built from the calendar date each time so a DST change never moves
    // the wall-clock time.
    for (var day = 0; ; day++) {
      final at = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + day,
        time.hour,
        time.minute,
      );
      if (at.weekday == weekday && at.isAfter(now)) return at;
    }
  }
}
