import 'package:ceniflix/core/error/failures.dart';
import 'package:ceniflix/core/usecases/app_usecase.dart';
import 'package:ceniflix/features/sensor/data/repositories/biometric_repository_impl.dart';
import 'package:ceniflix/features/sensor/domain/repositories/biometric_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginWithBiometricsParams extends Equatable {
  final String accountId;

  const LoginWithBiometricsParams({required this.accountId});

  @override
  List<Object?> get props => [accountId];
}

final loginWithBiometricsUsecaseProvider = Provider<LoginWithBiometricsUsecase>((ref) {
  final repository = ref.read(biometricRepositoryProvider);
  return LoginWithBiometricsUsecase(repository: repository);
});

class LoginWithBiometricsUsecase
    implements UsecaseWithParams<bool, LoginWithBiometricsParams> {
  final IBiometricRepository _repository;

  LoginWithBiometricsUsecase({required IBiometricRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, bool>> call(LoginWithBiometricsParams params) {
    return _repository.loginWithBiometrics(params.accountId);
  }
}
