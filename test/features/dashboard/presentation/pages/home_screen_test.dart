import 'package:ceniflix/features/dashboard/presentation/pages/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrapWithApp() {
    return MaterialApp(
      home: HomeScreen(
        homePageBuilder: (_) => const Center(child: Text('Home Body')),
        moviesPage: const Center(child: Text('Movies Page')),
        profilePage: const Center(child: Text('Profile Page')),
      ),
    );
  }

  testWidgets('Home: renders CineFlix app bar title', (tester) async {
    await tester.pumpWidget(wrapWithApp());

    expect(find.text('CineFlix'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('Home: shows bottom navigation items', (tester) async {
    await tester.pumpWidget(wrapWithApp());

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Home: default selected tab is Home', (tester) async {
    await tester.pumpWidget(wrapWithApp());

    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.currentIndex, 0);
    expect(find.text('Home Body'), findsOneWidget);
  });

  testWidgets('Home: tapping Movies tab updates selected index', (tester) async {
    await tester.pumpWidget(wrapWithApp());

    await tester.tap(find.byIcon(Icons.movie));
    await tester.pump();

    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.currentIndex, 1);
  });

  testWidgets('Home: tapping Movies tab shows movies page', (tester) async {
    await tester.pumpWidget(wrapWithApp());

    await tester.tap(find.byIcon(Icons.movie));
    await tester.pump();

    expect(find.text('Movies Page'), findsOneWidget);
  });
}