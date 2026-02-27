import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:ceniflix/core/api/api_client.dart';
import 'package:ceniflix/features/bottom_screens/presentation/pages/bookings_history_screen.dart';
import 'package:ceniflix/features/seats/data/datasources/remote/booking_remote_datasource.dart';
import 'package:ceniflix/features/splash/presentation/pages/splash_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ceniflix/app/themes/themes_data.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final BookingRemoteDataSource _bookingRemoteDataSource =
      BookingRemoteDataSource(ApiClient());

  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _listenForDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _listenForDeepLinks() async {
    final appLinks = AppLinks();

    try {
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleDeepLink(initialLink);
      }
    } catch (_) {}

    _deepLinkSubscription = appLinks.uriLinkStream.listen(
      (uri) async {
        await _handleDeepLink(uri);
      },
      onError: (_) {},
    );
  }

  bool _isKhaltiCallback(Uri uri) {
    if (uri.scheme.toLowerCase() != 'ceniflix') return false;

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    return host == 'payment-callback' ||
      host == 'history' ||
      path.contains('payment-callback') ||
      path.contains('history') ||
      uri.queryParameters.containsKey('bookingId') ||
      uri.queryParameters.containsKey('pidx');
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (!_isKhaltiCallback(uri)) return;

    final bookingId = (uri.queryParameters['bookingId'] ?? '').trim();
    final pidx = (uri.queryParameters['pidx'] ?? '').trim();

    if (bookingId.isNotEmpty && pidx.isNotEmpty) {
      try {
        final isVerified = await _bookingRemoteDataSource.verifyKhaltiPayment(
          bookingId: bookingId,
          pidx: pidx,
        );
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              isVerified
                  ? 'Payment successful. Booking updated.'
                  : 'Payment verification pending. Pull to refresh after a moment.',
            ),
          ),
        );
      } on DioException catch (e) {
        final message =
            (e.response?.data is Map<String, dynamic>)
                ? ((e.response?.data['message'] ?? 'Payment verification failed').toString())
                : 'Payment verification failed';
        _messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (_) {
        _messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Payment verification failed')),
        );
      }
    } else if (bookingId.isNotEmpty) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Returned from payment. Verifying booking status...'),
        ),
      );
    }

    final nav = _navigatorKey.currentState;
    if (nav == null) return;

    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BookingsHistoryScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      theme: getApplicationTheme(),
      home: const SplashScreen(),
     );
  }
}