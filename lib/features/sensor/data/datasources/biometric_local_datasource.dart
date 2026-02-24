import 'package:ceniflix/features/sensor/domain/entities/biometric_binding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final biometricLocalDatasourceProvider = Provider<IBiometricLocalDataSource>((ref) {
  return BiometricLocalDatasource(
    localAuth: LocalAuthentication(),
    secureStorage: const FlutterSecureStorage(),
  );
});

abstract interface class IBiometricLocalDataSource {
  Future<bool> isDeviceSupported();
  Future<bool> canCheckBiometrics();
  Future<List<BiometricType>> getAvailableBiometrics();
  Future<bool> authenticate({required String reason});
  Future<void> saveBinding(BiometricBinding binding);
  Future<BiometricBinding?> getBinding();
  Future<void> clearBinding();
}

class BiometricLocalDatasource implements IBiometricLocalDataSource {
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  static const String _keyBoundAccountId = 'biometric_account_id';
  static const String _keyBoundUserId = 'biometric_user_id';
  static const String _keyBoundEmail = 'biometric_user_email';
  static const String _keyBoundFullName = 'biometric_user_full_name';
  static const String _keyBoundToken = 'biometric_auth_token';

  BiometricLocalDatasource({
    required LocalAuthentication localAuth,
    required FlutterSecureStorage secureStorage,
  })  : _localAuth = localAuth,
        _secureStorage = secureStorage;

  @override
  Future<bool> isDeviceSupported() {
    return _localAuth.isDeviceSupported();
  }

  @override
  Future<bool> canCheckBiometrics() {
    return _localAuth.canCheckBiometrics;
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() {
    return _localAuth.getAvailableBiometrics();
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    return _localAuth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }

  @override
  Future<void> saveBinding(BiometricBinding binding) async {
    await _secureStorage.write(
      key: _keyBoundAccountId,
      value: binding.accountId,
    );

    if (binding.userId != null && binding.userId!.isNotEmpty) {
      await _secureStorage.write(
        key: _keyBoundUserId,
        value: binding.userId,
      );
    }

    if (binding.email != null && binding.email!.isNotEmpty) {
      await _secureStorage.write(
        key: _keyBoundEmail,
        value: binding.email,
      );
    }

    if (binding.fullName != null && binding.fullName!.isNotEmpty) {
      await _secureStorage.write(
        key: _keyBoundFullName,
        value: binding.fullName,
      );
    }

    if (binding.token != null && binding.token!.isNotEmpty) {
      await _secureStorage.write(
        key: _keyBoundToken,
        value: binding.token,
      );
    }
  }

  @override
  Future<BiometricBinding?> getBinding() async {
    final accountId = await _secureStorage.read(key: _keyBoundAccountId);
    if (accountId == null || accountId.isEmpty) {
      return null;
    }

    final userId = await _secureStorage.read(key: _keyBoundUserId);
    final email = await _secureStorage.read(key: _keyBoundEmail);
    final fullName = await _secureStorage.read(key: _keyBoundFullName);
    final token = await _secureStorage.read(key: _keyBoundToken);

    return BiometricBinding(
      accountId: accountId,
      userId: userId,
      email: email,
      fullName: fullName,
      token: token,
    );
  }

  @override
  Future<void> clearBinding() async {
    await _secureStorage.delete(key: _keyBoundAccountId);
    await _secureStorage.delete(key: _keyBoundUserId);
    await _secureStorage.delete(key: _keyBoundEmail);
    await _secureStorage.delete(key: _keyBoundFullName);
    await _secureStorage.delete(key: _keyBoundToken);
  }
}
