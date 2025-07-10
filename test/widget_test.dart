import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_app/main.dart';
import 'package:zxbase_app/ui/launch/splash_widget.dart';
import 'helpers.dart';

void main() {
  mockPathProvider();
  cleanupDb();

  testWidgets('Test first launch', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: SplashWidget(onInitializationComplete: () => startApp()),
        ),
      );

      // allow some time for init sequence
      await Future.delayed(const Duration(seconds: 3), () {});
    });
  });
}
