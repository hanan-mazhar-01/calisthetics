import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Host side of `integration_test/perf_test.dart`: writes the frame-timing
/// summaries the device reports to build/perf/perf_report.json.
///
///   flutter drive --profile --no-dds \
///     --driver=test_driver/perf_driver.dart \
///     --target=integration_test/perf_test.dart -d DEVICE_ID
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final dir = Directory('build/perf')..createSync(recursive: true);
    File('${dir.path}/perf_report.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  },
);
