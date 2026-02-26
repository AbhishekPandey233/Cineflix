import 'dart:io';

import 'package:ceniflix/features/seats/presentation/pages/seats.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http_overrides.dart';

void main() {
  const accelerometerChannel = MethodChannel(
    'dev.fluttercommunity.plus/sensors/accelerometer',
  );
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  late HttpOverrides? previousHttpOverrides;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = FakeHttpOverrides();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(accelerometerChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      if (call.method == 'read') return null;
      if (call.method == 'containsKey') return false;
      if (call.method == 'readAll') return <String, String>{};
      return null;
    });
  });

  tearDownAll(() {
    HttpOverrides.global = previousHttpOverrides;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(accelerometerChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  Widget wrapWithApp() {
    return const MaterialApp(
      home: SeatsScreen(showtimeId: 'show_1', movieTitle: 'Demo Movie'),
    );
  }

  Future<void> flushPendingAsyncWork(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> pumpUntilErrorState(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Seats: shows loading state on initial frame', (tester) async {
    addTearDown(() async => flushPendingAsyncWork(tester));

    await tester.pumpWidget(wrapWithApp());

    expect(find.text('Select Your Seats'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Seats: shows error state and retry after failed load',
      (tester) async {
    addTearDown(() async => flushPendingAsyncWork(tester));

    await tester.pumpWidget(wrapWithApp());
    await pumpUntilErrorState(tester);

    expect(find.text('Failed to load seats'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Seats: error state keeps app bar title visible',
      (tester) async {
    addTearDown(() async => flushPendingAsyncWork(tester));

    await tester.pumpWidget(wrapWithApp());
    await pumpUntilErrorState(tester);

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Select Your Seats'), findsWidgets);
  });

  testWidgets('Seats: error state uses black scaffold background',
      (tester) async {
    addTearDown(() async => flushPendingAsyncWork(tester));

    await tester.pumpWidget(wrapWithApp());
    await pumpUntilErrorState(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.black);
  });

  testWidgets('Seats: tapping retry remains stable when request fails',
      (tester) async {
    addTearDown(() async => flushPendingAsyncWork(tester));

    await tester.pumpWidget(wrapWithApp());
    await pumpUntilErrorState(tester);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await pumpUntilErrorState(tester);

    expect(find.text('Failed to load seats'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Seats: does not show seat summary in failure state', (tester) async {
    addTearDown(() async => flushPendingAsyncWork(tester));

    await tester.pumpWidget(wrapWithApp());
    await pumpUntilErrorState(tester);

    expect(find.text('Your Selection'), findsNothing);
    expect(find.text('Book Seats'), findsNothing);
  });
}