import 'package:calisthenics/features/profile/presentation/providers/reminder_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses and formats reminder times', () {
    expect(parseReminderTime('07:05'), const TimeOfDay(hour: 7, minute: 5));
    expect(parseReminderTime('25:00'), isNull);
    expect(parseReminderTime('bad'), isNull);
    expect(parseReminderTime(null), isNull);
    expect(formatReminderTime(const TimeOfDay(hour: 7, minute: 5)), '07:05');
  });

  test('default time follows the preferred time of day', () {
    expect(defaultReminderTime('evening').hour, 19);
    expect(defaultReminderTime('afternoon').hour, 13);
    expect(defaultReminderTime('morning').hour, 8);
    expect(defaultReminderTime(null).hour, 8);
  });
}
