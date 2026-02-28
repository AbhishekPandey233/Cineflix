import 'package:ceniflix/core/services/storage/user_session_service.dart';
import 'package:ceniflix/features/auth/presentation/pages/signup_screen.dart';
import 'package:ceniflix/features/bottom_screens/presentation/pages/bookings_history_screen.dart';
import 'package:ceniflix/features/bottom_screens/presentation/pages/profile.dart';
import 'package:ceniflix/features/bottom_screens/presentation/providers/profile_provider.dart';
import 'package:ceniflix/features/sensor/presentation/state/biometric_state.dart';
import 'package:ceniflix/features/sensor/presentation/view_model/biometric_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../helpers/fake_user_session_service.dart';
import '../../../../helpers/mock_dio.dart';

class _TestBiometricViewModel extends BiometricViewModel {
  @override
  BiometricState build() => const BiometricState();

  @override
  Future<bool> canUseForAccount(String accountId) async => false;

  @override
  Future<bool> enrollBiometrics({
    required String accountId,
    String? userId,
    String? email,
    String? fullName,
    String? token,
  }) async =>
      true;

  @override
  Future<void> clearBinding() async {}
}

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
        biometricViewModelProvider.overrideWith(() => _TestBiometricViewModel()),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  Future<void> flushPendingNetworkTimers(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 8));
  }

  testWidgets('Profile: tapping camera opens bottom sheet', (tester) async {
    addTearDown(() async => flushPendingNetworkTimers(tester));

    final fakeSession = FakeUserSessionService();

    await tester.pumpWidget(wrapWithApp(fakeSession: fakeSession));
    await tester.pump();

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Test User'), findsWidgets);
    expect(find.text('test@gmail.com'), findsWidgets);

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('Profile: logout navigates to SignupScreen', (tester) async {
    addTearDown(() async => flushPendingNetworkTimers(tester));

    final fakeSession = FakeUserSessionService();

    await tester.pumpWidget(wrapWithApp(fakeSession: fakeSession));
    await tester.pump();

    final logoutIcon = find.byIcon(Icons.logout);
    await tester.scrollUntilVisible(
      logoutIcon,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(logoutIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Confirm Logout'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SignupScreen), findsOneWidget);
    expect(fakeSession.cleared, isTrue);
  });

  testWidgets('Profile: shows primary action buttons', (tester) async {
    addTearDown(() async => flushPendingNetworkTimers(tester));

    final fakeSession = FakeUserSessionService();

    await tester.pumpWidget(wrapWithApp(fakeSession: fakeSession));
    await tester.pump();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);

    final logoutIcon = find.byIcon(Icons.logout);
    await tester.scrollUntilVisible(
      logoutIcon,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('Profile: tapping edit profile opens edit sheet', (tester) async {
    addTearDown(() async => flushPendingNetworkTimers(tester));

    final fakeSession = FakeUserSessionService();

    await tester.pumpWidget(wrapWithApp(fakeSession: fakeSession));
    await tester.pump();

    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsNWidgets(2));
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Profile: tapping bookings opens booking history screen', (tester) async {
    addTearDown(() async => flushPendingNetworkTimers(tester));

    final fakeSession = FakeUserSessionService();

    await tester.pumpWidget(wrapWithApp(fakeSession: fakeSession));
    await tester.pump();

    await tester.tap(find.text('Bookings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BookingsHistoryScreen), findsOneWidget);
  });
}
