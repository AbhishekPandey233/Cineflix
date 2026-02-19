import 'package:ceniflix/core/api/api_client.dart';
import 'package:ceniflix/features/seats/data/datasources/remote/booking_remote_datasource.dart';
import 'package:ceniflix/features/seats/data/models/user_booking_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class BookingsHistoryScreen extends StatefulWidget {
  const BookingsHistoryScreen({super.key});

  @override
  State<BookingsHistoryScreen> createState() => _BookingsHistoryScreenState();
}

class _BookingsHistoryScreenState extends State<BookingsHistoryScreen> {
  final BookingRemoteDataSource _bookingRemoteDataSource =
      BookingRemoteDataSource(ApiClient());

  List<UserBookingModel> _bookings = const [];
  bool _loading = true;
  String _error = '';
  String? _cancelingBookingId;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  String _extractApiError(DioException error, {required String fallback}) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final bookings = await _bookingRemoteDataSource.getUserBookings();

      if (!mounted) return;
      setState(() {
        _bookings = bookings;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _extractApiError(e, fallback: 'Failed to load bookings');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load bookings';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    setState(() {
      _cancelingBookingId = bookingId;
      _error = '';
    });

    try {
      await _bookingRemoteDataSource.cancelBooking(bookingId);
      if (!mounted) return;

      setState(() {
        _bookings = _bookings.where((b) => b.id != bookingId).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _extractApiError(e, fallback: 'Failed to cancel booking');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to cancel booking';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cancelingBookingId = null;
        });
      }
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year}, $hour:$minute $period';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }

  Future<void> _showCancelConfirm(String bookingId) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isLoading = _cancelingBookingId == bookingId;

        return AlertDialog(
          title: const Text('Cancel Booking?'),
          content: const Text(
            'Are you sure you want to cancel this booking? The seats will be released for other users.',
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
              child: const Text('Keep Booking'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: isLoading ? null : () => Navigator.of(context).pop(true),
              child: Text(isLoading ? 'Cancelling...' : 'Cancel Booking'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      await _cancelBooking(bookingId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = _bookings.fold<double>(
      0,
      (sum, booking) => sum + booking.totalPrice,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Booking History'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBookings,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0x33EF233C),
                            Color(0x1206B6D4),
                            Color(0x00000000),
                          ],
                        ),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'View your booked tickets and details.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _StatChip(
                                icon: Icons.confirmation_num_outlined,
                                label: 'Bookings',
                                value: '${_bookings.length}',
                              ),
                              _StatChip(
                                icon: Icons.payments_outlined,
                                label: 'Total Spent',
                                value: '₹${totalSpent.toStringAsFixed(0)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_error.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 14),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          _error,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    const SizedBox(height: 18),
                    if (_bookings.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              color: Colors.white70,
                              size: 26,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'No bookings yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your past tickets and receipts will appear here once you book seats.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Book Now'),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._bookings.map((booking) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                booking.movieTitle,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: booking.isConfirmed
                                                    ? const Color(0xFF065F46)
                                                    : Colors.grey.shade700,
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                booking.status.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        _DetailTile(
                                          icon: Icons.fingerprint,
                                          label: 'Booking ID',
                                          value:
                                              booking.id.length > 8
                                                  ? booking.id.substring(
                                                      booking.id.length - 8,
                                                    )
                                                  : booking.id,
                                        ),
                                        _DetailTile(
                                          icon: Icons.schedule,
                                          label: 'Showtime',
                                          value: _formatDateTime(booking.startTime),
                                        ),
                                        _DetailTile(
                                          icon: Icons.chair_alt_outlined,
                                          label: 'Hall',
                                          value: booking.hallName,
                                        ),
                                        _DetailTile(
                                          icon: Icons.event_seat_outlined,
                                          label: 'Seats',
                                          value: booking.seats.join(', '),
                                        ),
                                        _DetailTile(
                                          icon: Icons.calendar_today_outlined,
                                          label: 'Booked on',
                                          value: _formatDate(booking.createdAt),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${booking.totalPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 38,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${booking.seats.length} ${booking.seats.length == 1 ? 'seat' : 'seats'}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(height: 1, color: Colors.white12),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Book Again'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Download not available yet')),
                                      );
                                    },
                                    child: const Text('Download Ticket'),
                                  ),
                                  if (booking.isConfirmed)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.withValues(alpha: 0.20),
                                        foregroundColor: const Color(0xFFF87171),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () => _showCancelConfirm(booking.id),
                                      child: Text(
                                        _cancelingBookingId == booking.id
                                            ? 'Cancelling...'
                                            : 'Cancel Booking',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white60, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
