import 'package:flutter_test/flutter_test.dart';

/// Pumps frames for [duration] without waiting for all animations to stop
/// (unlike [WidgetTester.pumpAndSettle], which often hangs on this app).
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  final deadline = DateTime.now().add(duration);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Returns true if [finder] appears before [timeout].
Future<bool> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (tester.any(finder)) return true;
  }
  return false;
}

Future<void> waitForOrFail(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
  String? message,
}) async {
  final found = await waitFor(tester, finder, timeout: timeout);
  if (!found) {
    fail(message ?? 'Timed out waiting for $finder');
  }
}
