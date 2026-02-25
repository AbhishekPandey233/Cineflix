import 'package:ceniflix/features/bottom_screens/presentation/pages/movies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/fake_http_overrides.dart';
import 'dart:io';

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

  Future<void> drainAsyncWork(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('Movies: renders a scaffold', (tester) async {
    await tester.pumpWidget(wrapWithApp(const MoviesScreen()));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(MoviesScreen), findsOneWidget);
    await drainAsyncWork(tester);
  });

  testWidgets('Movies: shows loading indicator initially', (tester) async {
    await tester.pumpWidget(wrapWithApp(const MoviesScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await drainAsyncWork(tester);
  });

  testWidgets('Movies: uses dark scaffold background', (tester) async {
    await tester.pumpWidget(wrapWithApp(const MoviesScreen()));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF0D0D0D));
    await drainAsyncWork(tester);
  });

  testWidgets('Movies: shows an initial async state safely', (tester) async {
    await tester.pumpWidget(wrapWithApp(const MoviesScreen()));

    final hasLoader = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasHeading = find.text('Now Showing').evaluate().isNotEmpty;
    expect(hasLoader || hasHeading, isTrue);
    await drainAsyncWork(tester);
  });

  testWidgets('Movies: remains stable after a short async pump', (tester) async {
    await tester.pumpWidget(wrapWithApp(const MoviesScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(MoviesScreen), findsOneWidget);
    await drainAsyncWork(tester);
  });
}