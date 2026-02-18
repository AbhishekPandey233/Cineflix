import 'dart:io';
import 'package:ceniflix/core/api/api_endpoint.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ceniflix/core/services/storage/user_session_service.dart';
import 'package:ceniflix/features/bottom_screens/data/datasources/profile_remote_datasource.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: ApiEndpoints.connectionTimeout,
      receiveTimeout: ApiEndpoints.receiveTimeout,
    ),
  );
  
  // Add retry interceptor for network resilience
  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      retries: 2,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
      ],
      retryEvaluator: (error, attempt) {
        return error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError;
      },
    ),
  );
  
  return dio;
});

class ProfileState {
  final bool loading;
  final String? imageUrl;
  final String? error;

  const ProfileState({
    this.loading = false,
    this.imageUrl,
    this.error,
  });

  ProfileState copyWith({
    bool? loading,
    String? imageUrl,
    String? error,
  }) {
    return ProfileState(
      loading: loading ?? this.loading,
      imageUrl: imageUrl ?? this.imageUrl,
      error: error,
    );
  }
}

final profileProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  final dio = ref.read(dioProvider);
  final session = ref.read(userSessionServiceProvider);
  return ProfileController(dio, session);
});

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._dio, this._session) : super(const ProfileState());

  final Dio _dio;
  final UserSessionService _session;
  final ImagePicker _picker = ImagePicker();

  // ✅ NEW: load profile picture from backend (persistence)
  Future<void> loadProfile() async {
    try {
      final remote = ProfileRemoteDataSource(_dio, _session);
      final url = await remote.fetchProfilePictureUrl();
      if (url != null && url.isNotEmpty) {
        state = state.copyWith(imageUrl: url);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> pickAndUpload(ImageSource source) async {
    state = state.copyWith(loading: true, error: null);

    try {
      // Camera permission only when using camera
      if (source == ImageSource.camera) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          state = state.copyWith(
            loading: false,
            error: "Camera permission denied",
          );
          return;
        }
      }

      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (picked == null) {
        state = state.copyWith(loading: false);
        return;
      }

      final file = File(picked.path);

      final remote = ProfileRemoteDataSource(_dio, _session);
      final url = await remote.uploadProfilePicture(file);

      state = state.copyWith(
        loading: false,
        imageUrl: url,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  // ✅ NEW: clear local state on logout
  void clear() {
    state = const ProfileState();
  }
}
