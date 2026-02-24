import 'package:ceniflix/core/error/failures.dart';
import 'package:ceniflix/features/sensor/data/datasources/biometric_local_datasource.dart';
import 'package:ceniflix/features/sensor/domain/entities/biometric_binding.dart';
import 'package:ceniflix/features/sensor/domain/repositories/biometric_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

final biometricRepositoryProvider = Provider<IBiometricRepository>((ref) {
  final localDatasource = ref.read(biometricLocalDatasourceProvider);
  return BiometricRepositoryImpl(localDatasource: localDatasource);
});

class BiometricRepositoryImpl implements IBiometricRepository {
  final IBiometricLocalDataSource _localDatasource;

  String _normalizeAccountId(String accountId) {
    return accountId.trim().toLowerCase();
  }

  BiometricRepositoryImpl({required IBiometricLocalDataSource localDatasource})
      : _localDatasource = localDatasource;

  @override
  Future<Either<Failure, bool>> enroll(BiometricBinding binding) async {
    try {
      final normalizedAccountId = _normalizeAccountId(binding.accountId);
      final normalizedBinding = binding.accountId == normalizedAccountId
          ? binding
          : BiometricBinding(
              accountId: normalizedAccountId,
              userId: binding.userId,
              email: binding.email,
              fullName: binding.fullName,
              token: binding.token,
            );

      final supported = await _localDatasource.isDeviceSupported();
      if (!supported) {
        return const Left(BiometricFailure(
          message: 'Biometrics not supported on this device',
        ));
      }

      final canCheck = await _localDatasource.canCheckBiometrics();
      if (!canCheck) {
        return const Left(BiometricFailure(
          message: 'No biometrics enrolled on this device',
        ));
      }

      final available = await _localDatasource.getAvailableBiometrics();
      if (available.isEmpty) {
        return const Left(BiometricFailure(
          message: 'No biometrics available. Set up fingerprint or Face ID first.',
        ));
      }

      final authenticated = await _localDatasource.authenticate(
        reason: 'Enable biometric login for this account',
      );

      if (!authenticated) {
        return const Left(BiometricFailure(
          message: 'Biometric authentication was cancelled',
        ));
      }

      await _localDatasource.saveBinding(normalizedBinding);
      return const Right(true);
    } on PlatformException catch (e) {
      return Left(BiometricFailure(message: e.message ?? 'Biometric error'));
    } catch (e) {
      return Left(BiometricFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> canUseBiometrics(String accountId) async {
    try {
      final normalizedAccountId = _normalizeAccountId(accountId);
      final binding = await _localDatasource.getBinding();
      if (binding == null) {
        return const Right(false);
      }

      if (_normalizeAccountId(binding.accountId) != normalizedAccountId) {
        return const Right(false);
      }

      final supported = await _localDatasource.isDeviceSupported();
      if (!supported) {
        await _localDatasource.clearBinding();
        return const Right(false);
      }

      final canCheck = await _localDatasource.canCheckBiometrics();
      final available = await _localDatasource.getAvailableBiometrics();
      if (!canCheck || available.isEmpty) {
        await _localDatasource.clearBinding();
        return const Right(false);
      }

      return const Right(true);
    } on PlatformException catch (e) {
      return Left(BiometricFailure(message: e.message ?? 'Biometric error'));
    } catch (e) {
      return Left(BiometricFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BiometricBinding?>> getBinding() async {
    try {
      final binding = await _localDatasource.getBinding();
      return Right(binding);
    } on PlatformException catch (e) {
      return Left(BiometricFailure(message: e.message ?? 'Biometric error'));
    } catch (e) {
      return Left(BiometricFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> loginWithBiometrics(String accountId) async {
    try {
      final normalizedAccountId = _normalizeAccountId(accountId);
      final binding = await _localDatasource.getBinding();
      if (binding == null ||
          _normalizeAccountId(binding.accountId) != normalizedAccountId) {
        return const Left(BiometricFailure(
          message: 'Fingerprint is not enabled for this account on this device',
        ));
      }

      final supported = await _localDatasource.isDeviceSupported();
      final canCheck = await _localDatasource.canCheckBiometrics();
      final available = await _localDatasource.getAvailableBiometrics();
      if (!supported || !canCheck || available.isEmpty) {
        await _localDatasource.clearBinding();
        return const Left(BiometricFailure(
          message: 'Biometrics are no longer available on this device',
        ));
      }

      final authenticated = await _localDatasource.authenticate(
        reason: 'Authenticate to sign in',
      );

      if (!authenticated) {
        return const Left(BiometricFailure(
          message: 'Biometric authentication failed',
        ));
      }

      return const Right(true);
    } on PlatformException catch (e) {
      return Left(BiometricFailure(message: e.message ?? 'Biometric error'));
    } catch (e) {
      return Left(BiometricFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> clearBinding() async {
    try {
      await _localDatasource.clearBinding();
      return const Right(true);
    } catch (e) {
      return Left(BiometricFailure(message: e.toString()));
    }
  }
}
