import 'package:calisthenics/core/routing/app_shell.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/shared/widgets/glass/glass_surface.dart';
import 'package:calisthenics/shared/widgets/nav_icons.dart';
import 'package:calisthenics/shared/widgets/premium_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<int>> _pumpBar(
  WidgetTester tester, {
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final picked = <int>[];
  var current = 0;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: PremiumBottomNavigationBar(
            currentIndex: current,
            items: appTabs,
            onItemSelected: (i) => setState(() {
              current = i;
              picked.add(i);
            }),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  return picked;
}

Animation<double>? _animationOf(WidgetTester tester, NavIconKind kind) => tester
    .widgetList<NavIcon>(find.byType(NavIcon))
    .firstWhere((i) => i.kind == kind)
    .animation;

void main() {
  testWidgets('every icon paints, idle and active, at any point of its move', (
    tester,
  ) async {
    for (final kind in NavIconKind.values) {
      for (final activeness in [0.0, 0.5, 1.0]) {
        for (final t in [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0]) {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: NavIcon(
                  kind: kind,
                  color: Colors.black,
                  tone: Colors.black26,
                  activeness: activeness,
                  animation: AlwaysStoppedAnimation(t),
                ),
              ),
            ),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$kind $activeness $t',
          );
        }
      }
    }
  });

  test('the painter only repaints when something it draws changes', () {
    const a = NavIconPainter(
      kind: NavIconKind.plan,
      color: Colors.black,
      tone: Colors.black26,
      activeness: 0,
      t: 1,
    );
    const same = NavIconPainter(
      kind: NavIconKind.plan,
      color: Colors.black,
      tone: Colors.black26,
      activeness: 0,
      t: 1,
    );
    const later = NavIconPainter(
      kind: NavIconKind.plan,
      color: Colors.black,
      tone: Colors.black26,
      activeness: 0,
      t: 0.5,
    );
    expect(a.shouldRepaint(same), isFalse);
    expect(a.shouldRepaint(later), isTrue);
  });

  testWidgets('tapping a tab plays that icon\'s animation, and only that one', (
    tester,
  ) async {
    final picked = await _pumpBar(tester);
    for (final kind in NavIconKind.values) {
      expect(_animationOf(tester, kind), isNull, reason: 'idle: $kind');
    }

    await tester.tap(find.bySemanticsLabel('Discover'));
    await tester.pump(); // the animation's clock starts on the first frame
    await tester.pump(const Duration(milliseconds: 250));
    expect(picked, [1]);
    final playing = _animationOf(tester, NavIconKind.discover)!;
    expect(playing.value, inExclusiveRange(0, 1));
    expect(_animationOf(tester, NavIconKind.plan), isNull);
    expect(_animationOf(tester, NavIconKind.progress), isNull);

    await tester.pump(navIconDuration);
    expect(playing.value, 1);

    // Tapping the tab that is already active plays it again.
    await tester.tap(find.bySemanticsLabel('Discover'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(_animationOf(tester, NavIconKind.discover)!.value, lessThan(1));
    await tester.pump(navIconDuration);
  });

  testWidgets('with animations turned off the icon just sits at rest', (
    tester,
  ) async {
    await _pumpBar(tester, reduceMotion: true);
    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(_animationOf(tester, NavIconKind.profile)!.value, 1);
  });

  testWidgets(
    'the bar keeps its pill: 66 tall (64 + its edge), 44 in from each side',
    (tester) async {
      await _pumpBar(tester);
      final pill = tester.getSize(find.byType(GlassSurface));
      expect(pill.height, 66);
      expect(pill.width, 400 - 2 * 44);
      expect(find.byType(NavIcon), findsNWidgets(4));
      expect(
        tester.widgetList<NavIcon>(find.byType(NavIcon)).map((i) => i.size),
        everyElement(22),
      );
    },
  );
}
