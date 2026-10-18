import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/calendar/domain/activity_log.dart';
import 'package:calisthenics/features/calendar/presentation/screens/day_activity_screen.dart';
import 'package:calisthenics/features/calendar/presentation/widgets/add_activity_sheet.dart';
import 'package:calisthenics/features/calendar/presentation/widgets/calendar_section.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 10, 14, 9, 30);

CompletedSession _s(DateTime at, {String name = 'Workout', int min = 15}) =>
    CompletedSession(
      finishedAt: at,
      templateId: 'foundation-full-body',
      sessionName: name,
      durationSeconds: min * 60,
      exerciseNumbers: const [1, 2, 3],
    );

class _History extends HistoryNotifier {
  _History(this.items);
  final List<CompletedSession> items;
  @override
  List<CompletedSession> build() => items;
}

Future<ProviderContainer> _pump(
  WidgetTester t,
  Widget Function(WidgetRef ref) home, {
  List<CompletedSession> history = const [],
}) async {
  t.view.physicalSize = const Size(390, 1400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues({});
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      clockProvider.overrideWithValue(() => _today),
      historyProvider.overrideWith(() => _History(history)),
    ],
  );
  addTearDown(container.dispose);
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Consumer(builder: (_, ref, _) => home(ref))),
      ),
    ),
  );
  await t.pump(const Duration(milliseconds: 300));
  return container;
}

void main() {
  group('helpers', () {
    test('formats', () {
      expect(activityStamp(DateTime(2026, 10, 13, 11, 24)), 'Oct 13, 11:24 AM');
      expect(activityStamp(DateTime(2026, 10, 13, 0, 5)), 'Oct 13, 12:05 AM');
      expect(activityStamp(DateTime(2026, 10, 13, 15, 0)), 'Oct 13, 3:00 PM');
      expect(dayTitle(DateTime(2026, 10, 13)), 'OCT 13 2026');
      expect(longDate(DateTime(2026, 10, 13)), 'October 13, 2026');
      expect(monthTitle(DateTime(2026, 9, 1)), 'September 2026');
    });

    test('activitiesOn picks one day, oldest first', () {
      final h = [
        _s(DateTime(2026, 10, 13, 18)),
        _s(DateTime(2026, 10, 13, 8)),
        _s(DateTime(2026, 10, 12, 8)),
      ];
      final l = activitiesOn(h, DateTime(2026, 10, 13));
      expect(l, hasLength(2));
      expect(l.first.finishedAt.hour, 8);
    });

    test('a hand-logged activity is stamped now today, noon otherwise', () {
      final now = DateTime(2026, 10, 14, 9, 30);
      final a = manualActivity(
        name: ' Run ',
        minutes: 30,
        day: DateTime(2026, 10, 14),
        now: now,
      );
      expect(a.finishedAt, now);
      expect(a.sessionName, 'Run');
      expect(a.durationSeconds, 1800);
      expect(a.isManual, isTrue);
      final b = manualActivity(
        name: 'Walk',
        minutes: 20,
        day: DateTime(2026, 10, 10),
        now: now,
      );
      expect(b.finishedAt, DateTime(2026, 10, 10, 12));
    });
  });

  group('calendar', () {
    testWidgets('shows the month, pages back and forth, opens a day', (
      t,
    ) async {
      DateTime? opened;
      await _pump(
        t,
        (ref) => SingleChildScrollView(
          child: CalendarSection(
            history: [_s(DateTime(2026, 10, 8, 8))],
            today: _today,
            onAdd: () {},
            onDay: (d) => opened = d,
            onHistory: () {},
          ),
        ),
        history: [_s(DateTime(2026, 10, 8, 8))],
      );
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('MON'), findsOneWidget);
      expect(find.byTooltip('Next month'), findsNothing);
      await t.tap(find.bySemanticsLabel('Previous month'));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('September 2026'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Next month'));
      await t.pump(const Duration(milliseconds: 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('October 2026'), findsOneWidget);
      await t.tap(find.text('8'));
      expect(opened, DateTime(2026, 10, 8));
    });

    testWidgets('the future month can not be reached', (t) async {
      await _pump(
        t,
        (ref) => CalendarSection(
          history: const [],
          today: _today,
          onAdd: () {},
          onDay: (_) {},
          onHistory: () {},
        ),
      );
      final next = find.bySemanticsLabel('Next month');
      await t.tap(next, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('October 2026'), findsOneWidget);
    });
  });

  group('day page and add activity', () {
    testWidgets('lists the day and totals it', (t) async {
      await _pump(
        t,
        (ref) => DayActivityScreen(day: DateTime(2026, 10, 13)),
        history: [
          _s(DateTime(2026, 10, 13, 11, 24), name: 'Legs', min: 28),
          _s(DateTime(2026, 10, 12, 8), name: 'Other'),
        ],
      );
      expect(find.text('OCT 13 2026'), findsOneWidget);
      expect(find.text('Legs'), findsOneWidget);
      expect(find.text('Other'), findsNothing);
      expect(find.text('Oct 13, 11:24 AM'), findsOneWidget);
      expect(find.text('28 Mins · 3 exercises'), findsOneWidget);
      expect(find.text('28'), findsWidgets); // minutes total
    });

    testWidgets('an empty day says so', (t) async {
      await _pump(t, (ref) => DayActivityScreen(day: DateTime(2026, 10, 3)));
      expect(find.text('Nothing logged on this day.'), findsOneWidget);
    });

    testWidgets('Add Activity logs a workout, shown on that day', (t) async {
      final c = await _pump(
        t,
        (ref) => DayActivityScreen(day: DateTime(2026, 10, 10)),
      );
      await t.tap(find.text('Add Activity'));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Add Workout'), findsOneWidget);
      expect(find.text('October 10, 2026'), findsOneWidget);
      // Add stays disabled until a name and a length are filled.
      await t.tap(find.text('Add'));
      await t.pump(const Duration(milliseconds: 300));
      expect(c.read(historyProvider), isEmpty);
      await t.enterText(find.widgetWithText(TextField, 'Name'), 'Evening run');
      await t.enterText(find.widgetWithText(TextField, 'Minutes'), '35');
      await t.pump();
      await t.tap(find.text('Add'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      await t.pump(const Duration(milliseconds: 600));
      final log = c.read(historyProvider);
      expect(log, hasLength(1));
      expect(log.single.sessionName, 'Evening run');
      expect(log.single.durationSeconds, 35 * 60);
      expect(log.single.finishedAt, DateTime(2026, 10, 10, 12));
      expect(find.text('Evening run'), findsOneWidget);
    });

    testWidgets('Cancel closes without logging', (t) async {
      final c = await _pump(
        t,
        (ref) => Center(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAddActivity(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      await t.tap(find.text('Cancel'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Add Workout'), findsNothing);
      expect(c.read(historyProvider), isEmpty);
    });
  });
}
