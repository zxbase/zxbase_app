import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_app/main.dart';
import 'package:zxbase_app/ui/launch/splash_widget.dart';
import 'helpers.dart';

void main() {
  CustomBindings();
  mockPathProvider();

  testWidgets('Test regular launch', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: SplashWidget(onInitializationComplete: () => startApp()),
        ),
      );

      // allow init
      await Future.delayed(const Duration(seconds: 3), () {});

      // try wrong password
      await tester.enterText(
        find.byKey(const Key('passwordInput')),
        'wrong password',
      );
      await tester.tap(find.byKey(const Key('openVaultButton')));
      expect(find.text('Max Levchin'), findsNothing);

      // user will be locked out for 10 seconds
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 12), () {});

      // show password
      expect(find.byType(IconButton), findsOneWidget);
      await tester.tap(find.byType(IconButton));

      // put the password in
      await tester.enterText(
        find.byKey(const Key('passwordInput')),
        '4bGd#9g123',
      );
      await tester.tap(find.byKey(const Key('openVaultButton')));

      // allow some time for getting access
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3), () {});

      // allow some time to start page
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3), () {});
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3), () {});
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3), () {});
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3), () {});
      expect(find.text('Vault', skipOffstage: false), findsNWidgets(1));
      // debugDumpApp();

      // devices
      BottomNavigationBar bottomBar =
          find.byKey(const Key('bottomBar')).evaluate().first.widget
              as BottomNavigationBar;
      bottomBar.onTap!(1);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3), () {});
      expect(find.text('Devices'), findsNWidgets(3));
      // debugDumpApp();

      // settings
      bottomBar.onTap!(2);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3), () {});
      expect(find.text('Settings'), findsNWidgets(2));
      // debugDumpApp();

      // tap appearance
      ListTile appearance =
          find.byKey(const Key('Appearance')).evaluate().first.widget
              as ListTile;
      appearance.onTap!();
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3), () {});

      // tap about
      ListTile about =
          find.byKey(const Key('About')).evaluate().first.widget as ListTile;
      about.onTap!();
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3), () {});
    });
  });
}
