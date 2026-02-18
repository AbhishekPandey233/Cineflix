import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Configuration
  // Set true only when running on a real phone connected to the same Wi-Fi.
  // For Android emulator, keep this false so host resolves to 10.0.2.2.
  static const bool isPhysicalDevice = false;
  static const String _ipAddress = '192.168.1.78';
  static const int _port = 5000;

  // Base URLs
  static String get _host {
    if (isPhysicalDevice) return _ipAddress;
    if (kIsWeb || Platform.isIOS) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static String get serverUrl => 'http://$_host:$_port';
  static String get baseUrl => '$serverUrl/api';
  static String get mediaServerUrl => serverUrl;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String customers = '/users';
  static const String customerLogin = '/auth/login';
  static const String customerRegister = '/auth/register';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';

  static const String currentUserProfile = '/user/profile';
  static const String uploadUserAvatar = '/users/avatar';

  static String customerById(String id) => '/users/$id';
  static String uploadProfilePicture(String id) => '/users/$id/profile-picture';
}
