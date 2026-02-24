import 'package:ceniflix/features/sensor/data/repositories/biometric_repository_impl.dart';
import 'package:ceniflix/features/sensor/domain/entities/biometric_binding.dart';
import 'package:ceniflix/features/sensor/domain/usecases/can_use_biometrics_usecase.dart';
import 'package:ceniflix/features/sensor/domain/usecases/clear_biometric_binding_usecase.dart';
import 'package:ceniflix/features/sensor/domain/usecases/enroll_biometrics_usecase.dart';
import 'package:ceniflix/features/sensor/domain/usecases/login_with_biometrics_usecase.dart';
import 'package:ceniflix/features/sensor/domain/repositories/biometric_repository.dart';
import 'package:ceniflix/features/sensor/presentation/state/biometric_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final biometricViewModelProvider =
    NotifierProvider<BiometricViewModel, BiometricState>(() {
  return BiometricViewModel();
});

class BiometricViewModel extends Notifier<BiometricState> {
  late final EnrollBiometricsUsecase _enrollUsecase;
  late final CanUseBiometricsUsecase _canUseUsecase;
  late final LoginWithBiometricsUsecase _loginUsecase;
  late final ClearBiometricBindingUsecase _clearUsecase;
  late final IBiometricRepository _repository;

  @override
  BiometricState build() {
    _enrollUsecase = ref.read(enrollBiometricsUsecaseProvider);
    _canUseUsecase = ref.read(canUseBiometricsUsecaseProvider);
    _loginUsecase = ref.read(loginWithBiometricsUsecaseProvider);
    _clearUsecase = ref.read(clearBiometricBindingUsecaseProvider);
    _repository = ref.read(biometricRepositoryProvider);
    return const BiometricState();
  }

  Future<bool> enrollBiometrics({
    required String accountId,
    String? userId,
    String? email,
    String? fullName,
    String? token,
  }) async {
    state = state.copyWith(status: BiometricStatus.busy, errorMessage: null);

    final params = EnrollBiometricsParams(
      accountId: accountId,
      userId: userId,
      email: email,
      fullName: fullName,
      token: token,
    );

    final result = await _enrollUsecase(params);
    return result.fold(
      (failure) {
        state = state.copyWith(
          status: BiometricStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(status: BiometricStatus.idle);
        return true;
      },
    );
  }

  Future<bool> canUseForAccount(String accountId) async {
    final result = await _canUseUsecase(
      CanUseBiometricsParams(accountId: accountId),
    );
    return result.fold(
      (_) => false,
      (canUse) => canUse,
    );
  }

  Future<bool> loginWithBiometrics(String accountId) async {
    state = state.copyWith(status: BiometricStatus.busy, errorMessage: null);

    final result = await _loginUsecase(
      LoginWithBiometricsParams(accountId: accountId),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: BiometricStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(status: BiometricStatus.idle);
        return true;
      },
    );
  }

  Future<void> clearBinding() async {
    state = state.copyWith(status: BiometricStatus.busy, errorMessage: null);

    final result = await _clearUsecase();
    result.fold(
      (failure) {
        state = state.copyWith(
          status: BiometricStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(status: BiometricStatus.idle);
      },
    );
  }

  Future<BiometricBinding?> getBinding() async {
    final result = await _repository.getBinding();
    return result.fold(
      (_) => null,
      (binding) => binding,
    );
  }
}
