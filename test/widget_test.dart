import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bombay_casting/theme/app_theme.dart';

void main() {
  testWidgets('new app theme is applied', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: Center(child: Text('Bombay Casting Company'))),
      ),
    );

    final context = tester.element(find.text('Bombay Casting Company'));
    final theme = Theme.of(context);

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(find.text('Bombay Casting Company'), findsOneWidget);
  });
}
