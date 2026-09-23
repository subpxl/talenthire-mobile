import 'package:bombay_casting/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../pump_helpers.dart';
import 'test_config.dart';

/// Cold-starts the real app on device.
class E2eAppLaunch {
  E2eAppLaunch._();

  static IntegrationTestWidgetsFlutterBinding ensureBinding() {
    return IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Calls [app.main] and pumps through splash / version gate.
  static Future<void> coldStart(WidgetTester tester) async {
    app.main();
    await pumpFor(tester, E2eTestConfig.coldStartPump);
  }
}
