
import 'package:ceniflix/core/api/api_client.dart';
import 'package:ceniflix/core/api/api_endpoint.dart';
import 'package:ceniflix/core/services/storage/user_session_service.dart';
import 'package:ceniflix/features/auth/data/datasources/auth_datasource.dart';
import 'package:ceniflix/features/auth/data/models/auth_api_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

final authRemoteDatasourceProvider = Provider<IAuthRemoteDataSource>((ref) {
  return AuthRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    userSessionService: ref.read(userSessionServiceProvider),
  );
});

class AuthRemoteDatasource implements IAuthRemoteDataSource{

  final ApiClient _apiClient;
  final UserSessionService _userSessionService;

  AuthRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
  })  : _apiClient = apiClient,
        _userSessionService = userSessionService;

  @override
  Future<AuthApiModel?> getUserById(String authId) {
    // TODO: implement getUserById
    throw UnimplementedError();
  }

  @override
  Future<AuthApiModel?> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.customerLogin,
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.data['success'] == true) {
      final token = response.data['token'] as String?;
      if (token != null) {
        final userData = response.data['data'] as Map<String, dynamic>?;

        // Decode JWT token to get user ID
        final decodedToken = JwtDecoder.decode(token);
        final userId =
            (userData?['_id'] ?? decodedToken['id'] ?? '').toString();
        final fullName =
            (userData?['name'] ??
                    userData?['fullName'] ??
                    _userSessionService.getCurrentUserFullName() ??
                    '')
                .toString();

        // Save token
        await _userSessionService.saveToken(token);

        // Create user object with stored data
        final user = AuthApiModel(
          id: userId,
          fullName: fullName,
          email: email,
          password: null,
          username: fullName,
        );

        // Update stored session with latest info
        await _userSessionService.saveUserSession(
          userId: userId,
          email: email,
          fullName: user.fullName,
        );

        return user;
      }
    }

    return null;
  }

  @override
  Future<AuthApiModel> register(AuthApiModel user) async {
    final payload = {
      ...user.toJson(),
      'confirmPassword': user.password,
    };

    final response = await _apiClient.post(
      ApiEndpoints.customerRegister,
      data: payload,
    );
    if (response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      final registeredUser = AuthApiModel.fromJson(data);

      // Save user data locally for future login
      await _userSessionService.saveUserSession(
        userId: registeredUser.id!,
        email: registeredUser.email,
        fullName: registeredUser.fullName, 
      );

      return registeredUser;
    } else {
      throw Exception(response.data['message'] ?? 'Registration failed');
    }
  }
  
  
}