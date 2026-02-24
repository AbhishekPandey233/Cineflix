import 'package:ceniflix/core/error/failures.dart';
import 'package:ceniflix/features/sensor/domain/entities/biometric_binding.dart';
import 'package:dartz/dartz.dart';

abstract interface class IBiometricRepository {
  Future<Either<Failure, bool>> enroll(BiometricBinding binding);
  Future<Either<Failure, bool>> canUseBiometrics(String accountId);
  Future<Either<Failure, bool>> loginWithBiometrics(String accountId);
  Future<Either<Failure, bool>> clearBinding();
  Future<Either<Failure, BiometricBinding?>> getBinding();
}
