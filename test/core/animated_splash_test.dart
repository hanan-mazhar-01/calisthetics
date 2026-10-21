import 'package:calisthenics/core/splash/animated_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('splash plays, then reports done', (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(home: AnimatedSplash(onDone: () => done = true)),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(done, isFalse);
    await tester.pump(const Duration(milliseconds: 2200));
    expect(done, isTrue);
  });

  testWidgets('SplashHost shows the app straight away under test', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashHost(child: Text('app'))),
    );
    expect(find.text('app'), findsOneWidget);
    expect(find.byType(AnimatedSplash), findsNothing);
  });
}
