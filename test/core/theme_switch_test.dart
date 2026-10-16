import 'package:calisthenics/core/theme/app_colors_extension.dart';
import 'package:calisthenics/core/theme/app_motion.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('light to dark fades through in-between colours', (t) async {
    final mode = ValueNotifier(ThemeMode.light);
    Color? seen;
    await t.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: mode,
        builder: (_, m, _) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: m,
          themeAnimationDuration: AppDurations.themeSwitch,
          themeAnimationCurve: Curves.easeInOutCubic,
          home: Builder(
            builder: (context) {
              seen = context.appColors.background;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final light = seen!;
    mode.value = ThemeMode.dark;
    await t.pump();
    await t.pump(AppDurations.themeSwitch * 0.5);
    final mid = seen!;
    await t.pump(AppDurations.themeSwitch);
    final dark = seen!;
    expect(light, isNot(dark));
    expect(mid, isNot(light));
    expect(mid, isNot(dark));
    expect(AppDurations.themeSwitch.inMilliseconds, greaterThanOrEqualTo(600));
  });
}
