import 'package:ceniflix/core/services/storage/user_session_service.dart';
import 'package:ceniflix/features/auth/presentation/pages/signup_screen.dart';
import 'package:ceniflix/features/bottom_screens/presentation/pages/profile.dart';
import 'package:ceniflix/features/bottom_screens/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../helpers/fake_user_session_service.dart';
import '../../../../helpers/mock_dio.dart';

void main() {
  Widget wrapWithApp({
    required FakeUserSessionService fakeSession,
  }) {
    final mockDio = MockDio();

    final controller = ProfileController(mockDio, fakeSession);

    return ProviderScope(
      overrides: [
        // session provider override
        userSessionServiceProvider.overrideWithValue(fakeSession),

        profileProvider.overrideWith((ref) => controller),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  testWidgets('Profile: tapping camera opens bottom sheet', (tester) async {
    final fakeSession = FakeUserSessionService();

    await tester.pumpWidget(wrapWithApp(fakeSession: fakeSession));
    await tester.pump(); 

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Test User'), findsWidgets);
    expect(find.text('test@gmail.com'), findsWidgets);

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('Profile: logout navigates to SignupScreen', (tester) async {
    final fakeSession = FakeUserSessionService();

    await tester.pumpWidget(wrapWithApp(fakeSession: fakeSession));
    await tester.pump();

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.byType(SignupScreen), findsOneWidget);
    expect(fakeSession.cleared, isTrue);
  });
}
