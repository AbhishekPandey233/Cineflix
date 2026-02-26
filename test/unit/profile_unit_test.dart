import 'package:ceniflix/features/bottom_screens/presentation/providers/profile_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ceniflix/core/services/storage/user_session_service.dart';

class MockDio extends Mock implements Dio {}
class MockUserSessionService extends Mock implements UserSessionService {}

void main() {
  test('ProfileState: default values are correct', () {
    final state = ProfileState();

    expect(state.loading, false);
    expect(state.imageUrl, isNull);
    expect(state.error, isNull);
  });

  test('ProfileController.clear(): resets ProfileState', () {
    final dio = MockDio();
    final session = MockUserSessionService();

    final controller = ProfileController(dio, session);

    controller.state = ProfileState(
      loading: true,
      imageUrl: 'https://example.com/img.png',
      error: 'Error happened',
    );

    controller.clear();

    expect(controller.state.loading, false);

    expect(controller.state.imageUrl, anyOf(isNull, ''));

    expect(controller.state.error, isNull);
  });

  test('ProfileController: starts with default state', () {
    final dio = MockDio();
    final session = MockUserSessionService();

    final controller = ProfileController(dio, session);

    expect(controller.state.loading, isFalse);
    expect(controller.state.imageUrl, isNull);
    expect(controller.state.error, isNull);
  });

  test('ProfileState.copyWith(): updates loading and keeps imageUrl', () {
    const initial = ProfileState(
      loading: false,
      imageUrl: 'https://example.com/old.png',
      error: 'old error',
    );

    final updated = initial.copyWith(loading: true);

    expect(updated.loading, isTrue);
    expect(updated.imageUrl, 'https://example.com/old.png');
    expect(updated.error, isNull);
  });

  test('ProfileState.copyWith(): updates imageUrl and explicit error', () {
    const initial = ProfileState();

    final updated = initial.copyWith(
      imageUrl: 'https://example.com/new.png',
      error: 'Upload failed',
    );

    expect(updated.loading, isFalse);
    expect(updated.imageUrl, 'https://example.com/new.png');
    expect(updated.error, 'Upload failed');
  });

  test('ProfileController.clear(): is idempotent on default state', () {
    final dio = MockDio();
    final session = MockUserSessionService();

    final controller = ProfileController(dio, session);

    controller.clear();
    controller.clear();

    expect(controller.state.loading, isFalse);
    expect(controller.state.imageUrl, isNull);
    expect(controller.state.error, isNull);
  });
}
