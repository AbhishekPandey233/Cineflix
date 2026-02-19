import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ceniflix/core/api/api_endpoint.dart';
import 'package:ceniflix/core/services/storage/user_session_service.dart';

class ProfileRemoteDataSource {
  final Dio _dio;
  final UserSessionService _session;

  ProfileRemoteDataSource(this._dio, this._session);

  // ✅ NEW: fetch saved profile picture from backend (persistence)
  Future<String?> fetchProfilePictureUrl() async {
    final token = await _session.getToken();

    if (token == null || token.isEmpty) return null;

    final res = await _dio.get(
      ApiEndpoints.currentUserProfile,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final data = res.data['data'] as Map<String, dynamic>?;
    var profilePath = (data?['image'] ?? '').toString();
    if (profilePath.isEmpty) return null;

    if (profilePath.startsWith('http')) {
      // If backend returned localhost URL, extract path and rebuild
      if (profilePath.contains('localhost:5000') || profilePath.contains('127.0.0.1:5000')) {
        try {
          final uri = Uri.parse(profilePath);
          profilePath = uri.path; // e.g., "/uploads/users/..."
          return '${ApiEndpoints.serverUrl}$profilePath';
        } catch (e) {
          // Fallback to simple string replacement
          return profilePath
              .replaceAll('http://localhost:5000', ApiEndpoints.serverUrl)
              .replaceAll('http://127.0.0.1:5000', ApiEndpoints.serverUrl);
        }
      }
      return profilePath; // URL is already correct
    }

    return '${ApiEndpoints.serverUrl}$profilePath';
  }

  Future<String> uploadProfilePicture(File file) async {
    final token = await _session.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("Token missing. Please login again.");
    }

    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path),
    });

    final response = await _dio.post(
      ApiEndpoints.uploadUserAvatar,
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    // Prefer path field (backend should always return this)
    // so URL is constructed client-side with correct emulator host
    var path = (response.data['path'] ?? '').toString();
    if (path.isNotEmpty) return '${ApiEndpoints.serverUrl}$path';

    // Fallback to url, but sanitize localhost → emulator host
    var url = (response.data['url'] ?? '').toString();
    if (url.isNotEmpty) {
      // If backend returned localhost URL, extract path and rebuild with correct host
      if (url.contains('localhost:5000') || url.contains('127.0.0.1:5000')) {
        // Extract path from URL: http://localhost:5000/uploads/users/1771400475031-500798938.jpg → /uploads/users/1771400475031-500798938.jpg
        try {
          final uri = Uri.parse(url);
          path = uri.path; // e.g., "/uploads/users/..."
          return '${ApiEndpoints.serverUrl}$path';
        } catch (e) {
          // Fallback to simple string replacement if parsing fails
          return url
              .replaceAll('http://localhost:5000', ApiEndpoints.serverUrl)
              .replaceAll('http://127.0.0.1:5000', ApiEndpoints.serverUrl);
        }
      }
      return url;
    }

    throw Exception('Upload failed: image URL not returned by server');
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    final token = await _session.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("Token missing. Please login again.");
    }

    final formData = FormData.fromMap({
      'name': name,
      'email': email,
    });

    final response = await _dio.put(
      ApiEndpoints.currentUserProfile,
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final data = response.data['data'];
    if (data is Map<String, dynamic>) return data;

    return <String, dynamic>{};
  }
}
