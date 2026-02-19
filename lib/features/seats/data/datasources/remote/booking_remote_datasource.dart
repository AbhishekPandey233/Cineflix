import 'package:ceniflix/core/api/api_client.dart';
import 'package:ceniflix/core/api/api_endpoint.dart';
import 'package:ceniflix/features/seats/data/models/seat_availability_model.dart';
import 'package:ceniflix/features/seats/data/models/showtime_api_model.dart';
import 'package:ceniflix/features/seats/data/models/user_booking_model.dart';

class BookingRemoteDataSource {
  BookingRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ShowtimeApiModel>> getShowtimesByMovie(String movieId) async {
    final response = await _apiClient.get(ApiEndpoints.showtimesByMovie(movieId));
    final root = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};

    final rawList = root['data'];
    if (rawList is! List) return [];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(ShowtimeApiModel.fromJson)
        .toList();
  }

  Future<SeatAvailabilityModel> getSeatAvailability(String showtimeId) async {
    final response = await _apiClient.get(ApiEndpoints.seatAvailability(showtimeId));

    final root = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final rawData = root['data'];

    if (rawData is! Map<String, dynamic>) {
      throw Exception('Invalid seat availability response');
    }

    return SeatAvailabilityModel.fromJson(rawData);
  }

  Future<String?> createBooking({
    required String showtimeId,
    required List<String> seats,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.bookings,
      data: {
        'showtimeId': showtimeId,
        'seats': seats,
      },
    );

    final root = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final rawData = root['data'];

    if (rawData is Map<String, dynamic>) {
      return rawData['_id']?.toString();
    }

    return null;
  }

  Future<List<UserBookingModel>> getUserBookings() async {
    final response = await _apiClient.get(ApiEndpoints.userBookingHistory);
    final root = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final rawList = root['data'];

    if (rawList is! List) return [];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(UserBookingModel.fromJson)
        .toList();
  }

  Future<void> cancelBooking(String bookingId) async {
    await _apiClient.delete(ApiEndpoints.cancelBooking(bookingId));
  }
}
