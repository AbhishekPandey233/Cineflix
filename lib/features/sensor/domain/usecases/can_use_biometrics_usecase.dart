import 'package:ceniflix/core/error/failures.dart';
import 'package:ceniflix/core/usecases/app_usecase.dart';
import 'package:ceniflix/features/sensor/data/repositories/biometric_repository_impl.dart';
import 'package:ceniflix/features/sensor/domain/repositories/biometric_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CanUseBiometricsParams extends Equatable {
  final String accountId;

  const CanUseBiometricsParams({required this.accountId});

  @override
  List<Object?> get props => [accountId];
}

final canUseBiometricsUsecaseProvider = Provider<CanUseBiometricsUsecase>((ref) {
  final repository = ref.read(biometricRepositoryProvider);
  return CanUseBiometricsUsecase(repository: repository);
});

class CanUseBiometricsUsecase
    implements UsecaseWithParams<bool, CanUseBiometricsParams> {
  final IBiometricRepository _repository;

  CanUseBiometricsUsecase({required IBiometricRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, bool>> call(CanUseBiometricsParams params) {
    return _repository.canUseBiometrics(params.accountId);
  }
}
