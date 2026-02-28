import 'dart:io';

import 'package:ceniflix/features/bottom_screens/presentation/pages/bookings_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http_overrides.dart';

void main() {
  late HttpOverrides? previousHttpOverrides;

  setUpAll(() {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = FakeHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = previousHttpOverrides;
  });

  Widget wrapWithApp(Widget child) {
    return MaterialApp(home: child);
  }

  Future<void> flushPendingNetworkTimers(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 8));
  }

  testWidgets('Bookings History: renders scaffold and app bar title', (tester) async {
    await tester.pumpWidget(wrapWithApp(const BookingsHistoryScreen()));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Booking History'), findsWidgets);

    await flushPendingNetworkTimers(tester);
  });

  testWidgets('Bookings History: shows loading indicator initially', (tester) async {
    await tester.pumpWidget(wrapWithApp(const BookingsHistoryScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await flushPendingNetworkTimers(tester);
  });

  testWidgets('Bookings History: uses black scaffold background', (tester) async {
    await tester.pumpWidget(wrapWithApp(const BookingsHistoryScreen()));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.black);

    await flushPendingNetworkTimers(tester);
  });

  testWidgets('Bookings History: provides pull-to-refresh wrapper', (tester) async {
    await tester.pumpWidget(wrapWithApp(const BookingsHistoryScreen()));

    expect(find.byType(RefreshIndicator), findsOneWidget);

    await flushPendingNetworkTimers(tester);
  });

  testWidgets('Bookings History: remains stable after short async pump', (tester) async {
    await tester.pumpWidget(wrapWithApp(const BookingsHistoryScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BookingsHistoryScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    await flushPendingNetworkTimers(tester);
  });
}