import 'package:ceniflix/core/error/failures.dart';
import 'package:ceniflix/core/usecases/app_usecase.dart';
import 'package:ceniflix/features/sensor/data/repositories/biometric_repository_impl.dart';
import 'package:ceniflix/features/sensor/domain/repositories/biometric_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clearBiometricBindingUsecaseProvider = Provider<ClearBiometricBindingUsecase>((ref) {
  final repository = ref.read(biometricRepositoryProvider);
  return ClearBiometricBindingUsecase(repository: repository);
});

class ClearBiometricBindingUsecase implements UsecaseWithout<bool> {
  final IBiometricRepository _repository;

  ClearBiometricBindingUsecase({required IBiometricRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, bool>> call() {
    return _repository.clearBinding();
  }
}
