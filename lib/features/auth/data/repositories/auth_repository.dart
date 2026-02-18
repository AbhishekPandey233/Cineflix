import 'package:ceniflix/core/error/failures.dart';
import 'package:ceniflix/core/services/connectivity/network_info.dart';
import 'package:ceniflix/features/auth/data/datasources/auth_datasource.dart';
import 'package:ceniflix/features/auth/data/datasources/local/auth_local_datasourse.dart';
import 'package:ceniflix/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:ceniflix/features/auth/data/models/auth_api_model.dart';
import 'package:ceniflix/features/auth/data/models/auth_hive_model.dart';
import 'package:ceniflix/features/auth/domain/entities/auth_entity.dart';
import 'package:ceniflix/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

//provider
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final authDatasource = ref.read(authLocalDatasourceProvider) as IAuthLocalDataSource;
  final authRemoteDatasource = ref.read(authRemoteDatasourceProvider);
  final networkInfo = ref.read(networkInfoProvider);
  return AuthRepository(
    authDatasource: authDatasource,
    authRemoteDataSource: authRemoteDatasource,
    networkInfo: networkInfo,
  );
});

class AuthRepository implements IAuthRepository{

  final IAuthLocalDataSource _authDataSource;
  final IAuthRemoteDataSource _authRemoteDataSource;
  final NetworkInfo _networkInfo;

  AuthRepository({
    required IAuthLocalDataSource authDatasource,
    required IAuthRemoteDataSource authRemoteDataSource,
    required NetworkInfo networkInfo,
  })  : _authDataSource = authDatasource,
        _authRemoteDataSource = authRemoteDataSource,
        _networkInfo = networkInfo;
  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    try {
      final model = await _authDataSource.getCurrentUser();
      if (model != null) {
        final entity = model.toEntity();
        return Right(entity);
      }
      return const Left(LocalDatabaseFailure(message: "No user logged in"));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
    
  }

  @override
  Future<Either<Failure, AuthEntity>> login(
    String email,
    String password,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final apiModel = await _authRemoteDataSource.login(email, password);
        if (apiModel != null) {
          final entity = apiModel.toEntity();
          return Right(entity);
        }
        return const Left(ApiFailure(message: "Invalid email or password"));
      } on DioException catch (e) {
        final message =
            e.response?.data?['message']?.toString() ??
            (e.type == DioExceptionType.connectionTimeout ||
                    e.type == DioExceptionType.connectionError
                ? 'Cannot reach server. Check API host/IP and backend status.'
                : 'Login failed');
        return Left(ApiFailure(
          message: message,
          statusCode: e.response?.statusCode,
          ));
      } catch (e) {
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      try {
        final model = await _authDataSource.login(email, password);
        if (model != null) {
          final entity = model.toEntity();
          return Right(entity);
        }
        return const Left(
          LocalDatabaseFailure(message: "Invalid email or password"),
        );
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      final result = await _authDataSource.logout();
      if (result) {
        return const Right(true);
      }
      return const Left(LocalDatabaseFailure(message: "Failed to logout"));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> register(AuthEntity user) async {
    if (await _networkInfo.isConnected) {
      try {
        final apiModel = AuthApiModel.fromEntity(user);
        await _authRemoteDataSource.register(apiModel);
        return const Right(true);
      } on DioException catch (e) {
        final message =
            e.response?.data?['message']?.toString() ??
            (e.type == DioExceptionType.connectionTimeout ||
                    e.type == DioExceptionType.connectionError
                ? 'Cannot reach server. Check API host/IP and backend status.'
                : 'Registration failed');
        return Left(ApiFailure(
          message: message,
          statusCode: e.response?.statusCode,
          ));
      } catch (e) {
        return Left(ApiFailure(message: e.toString()));
      }
    }else {
      try {
        // Check if email already exists
        final existingUser = await _authDataSource.getUserByEmail(user.email);
        if (existingUser != null) {
          return const Left(
            LocalDatabaseFailure(message: "Email already registered"),
          );
        }
        final authModel = AuthHiveModel(
          fullName: user.fullName,
          email: user.email,
          password: user.password, 
          username: user.username,
        );
        await _authDataSource.register(authModel);
        return const Right(true);
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    }
  }
}