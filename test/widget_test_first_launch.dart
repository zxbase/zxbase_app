import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_app/main.dart';
import 'package:zxbase_app/ui/launch/splash_widget.dart';
import 'package:zxbase_app/ui/common/zx_input.dart';
import 'helpers.dart';

void main() {
  CustomBindings();
  mockPathProvider();
  cleanupDb();

  testWidgets('Test first launch', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: SplashWidget(onInitializationComplete: () => startApp()),
        ),
      );

      // allow init
      await Future.delayed(const Duration(seconds: 3), () {});

      // make passwords visible
      expect(find.byType(IconButton), findsNWidgets(2));
      await tester.tap(find.byKey(const Key('passwordVisible')));
      await tester.tap(find.byKey(const Key('passwordVisibleConfirmation')));

      // put the password in
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.byType(ZXTextFormField), findsNWidgets(2));
      await tester.enterText(
        find.byKey(const Key('passwordInput')),
        '4bGd#9g123',
      );
      await tester.enterText(
        find.byKey(const Key('passwordConfirmationInput')),
        '4bGd#9g123',
      );

      await tester.tap(find.byKey(const Key('initVaultButton')));

      // Allow updates to propagate: init vault, complete launch.
      await Future.delayed(const Duration(seconds: 3), () {});
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3), () {});
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3), () {});
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3), () {});
      await tester.pumpAndSettle();
      // debugDumpApp();
      expect(find.text('Vault', skipOffstage: false), findsNWidgets(1));
    });
  });
}
