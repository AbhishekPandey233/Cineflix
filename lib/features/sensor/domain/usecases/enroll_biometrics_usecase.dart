import 'package:ceniflix/core/error/failures.dart';
import 'package:ceniflix/core/usecases/app_usecase.dart';
import 'package:ceniflix/features/sensor/data/repositories/biometric_repository_impl.dart';
import 'package:ceniflix/features/sensor/domain/entities/biometric_binding.dart';
import 'package:ceniflix/features/sensor/domain/repositories/biometric_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnrollBiometricsParams extends Equatable {
  final String accountId;
  final String? userId;
  final String? email;
  final String? fullName;
  final String? token;

  const EnrollBiometricsParams({
    required this.accountId,
    this.userId,
    this.email,
    this.fullName,
    this.token,
  });

  @override
  List<Object?> get props => [accountId, userId, email, fullName, token];
}

final enrollBiometricsUsecaseProvider = Provider<EnrollBiometricsUsecase>((ref) {
  final repository = ref.read(biometricRepositoryProvider);
  return EnrollBiometricsUsecase(repository: repository);
});

class EnrollBiometricsUsecase
    implements UsecaseWithParams<bool, EnrollBiometricsParams> {
  final IBiometricRepository _repository;

  EnrollBiometricsUsecase({required IBiometricRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, bool>> call(EnrollBiometricsParams params) {
    final binding = BiometricBinding(
      accountId: params.accountId,
      userId: params.userId,
      email: params.email,
      fullName: params.fullName,
      token: params.token,
    );
    return _repository.enroll(binding);
  }
}
