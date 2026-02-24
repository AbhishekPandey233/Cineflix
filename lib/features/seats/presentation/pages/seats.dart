import 'package:ceniflix/core/api/api_client.dart';
import 'package:ceniflix/features/seats/data/datasources/remote/booking_remote_datasource.dart';
import 'package:ceniflix/features/seats/data/models/seat_availability_model.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SeatsScreen extends StatefulWidget {
  const SeatsScreen({
    required this.showtimeId,
    this.movieTitle,
    super.key,
  });

  final String showtimeId;
  final String? movieTitle;

  @override
  State<SeatsScreen> createState() => _SeatsScreenState();
}

class _SeatsScreenState extends State<SeatsScreen> {
  static const int _maxSeats = 10;
  static const double _shakeThreshold = 18.0;
  static const Duration _shakeDebounce = Duration(milliseconds: 900);

  final BookingRemoteDataSource _bookingRemoteDataSource =
      BookingRemoteDataSource(ApiClient());

  bool _loading = true;
  bool _booking = false;
  String _error = '';

  SeatAvailabilityModel? _seatData;
  final Set<String> _selectedSeats = <String>{};
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastShakeAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _shakeConfirmDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSeatAvailability();
    _startShakeListener();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _startShakeListener() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final now = DateTime.now();
      if (now.difference(_lastShakeAt) < _shakeDebounce) {
        return;
      }

      final magnitude =
          math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude < _shakeThreshold) {
        return;
      }

      _lastShakeAt = now;
      _onShakeDetected();
    });
  }

  Future<void> _onShakeDetected() async {
    if (!mounted || _booking || _selectedSeats.isEmpty) return;

    if (_shakeConfirmDialogVisible) {
      Navigator.of(context, rootNavigator: true).pop(true);
      return;
    }

    await _showShakeBookingConfirmation();
  }

  Future<void> _showShakeBookingConfirmation() async {
    if (_selectedSeats.isEmpty || _booking || _shakeConfirmDialogVisible) return;

    _shakeConfirmDialogVisible = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final selected = _selectedSeats.toList()..sort();

        return AlertDialog(
          title: const Text('Confirm Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seats: ${selected.join(', ')}'),
              const SizedBox(height: 6),
              Text('Quantity: ${selected.length}'),
              const SizedBox(height: 6),
              Text(
                'Total Price: ₹${_totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Shake your phone again to confirm booking.',
                style: TextStyle(color: Colors.black87, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    _shakeConfirmDialogVisible = false;

    if (confirmed == true) {
      await _confirmBooking();
    }
  }

  Future<void> _loadSeatAvailability() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final data = await _bookingRemoteDataSource.getSeatAvailability(
        widget.showtimeId,
      );

      if (!mounted) return;
      setState(() {
        _seatData = data;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _extractApiError(e, fallback: 'Failed to load seats');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load seats';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
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

  bool get _limitReached => _selectedSeats.length >= _maxSeats;

  double get _pricePerSeat => _seatData?.price ?? 0;

  double get _totalPrice => _selectedSeats.length * _pricePerSeat;

  Set<String> get _bookedSet =>
      (_seatData?.bookedSeats ?? const <String>[]).map((s) => s.toUpperCase()).toSet();

  void _toggleSeat(String seatLabel) {
    final normalized = seatLabel.toUpperCase();
    if (_bookedSet.contains(normalized)) return;

    setState(() {
      if (_selectedSeats.contains(normalized)) {
        _selectedSeats.remove(normalized);
        return;
      }

      if (_selectedSeats.length >= _maxSeats) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can select up to 10 seats only.')),
        );
        return;
      }

      _selectedSeats.add(normalized);
    });
  }

  Future<void> _clearSelectionConfirm() async {
    if (_selectedSeats.isEmpty) return;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear selection?'),
          content: const Text('This will deselect all chosen seats.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true && mounted) {
      setState(_selectedSeats.clear);
    }
  }

  Future<void> _showBookingConfirmation() async {
    if (_selectedSeats.isEmpty || _booking) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final selected = _selectedSeats.toList()..sort();

        return AlertDialog(
          title: const Text('Confirm Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seats: ${selected.join(', ')}'),
              const SizedBox(height: 6),
              Text('Quantity: ${selected.length}'),
              const SizedBox(height: 6),
              Text(
                'Total Price: ₹${_totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _confirmBooking();
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedSeats.isEmpty || _booking) return;

    setState(() {
      _booking = true;
      _error = '';
    });

    try {
      final selected = _selectedSeats.toList()..sort();
      final bookingId = await _bookingRemoteDataSource.createBooking(
        showtimeId: widget.showtimeId,
        seats: selected,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bookingId != null
                ? 'Booking successful (#$bookingId)'
                : 'Booking successful',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final fallback = status == 401
          ? 'Please login first to complete booking'
          : 'Booking failed';

      setState(() {
        _error = _extractApiError(e, fallback: fallback);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Booking failed';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _booking = false;
      });
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Select Your Seats'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty && _seatData == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Select Your Seats'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadSeatAvailability,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final seatData = _seatData;
    if (seatData == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Select Your Seats'),
        ),
        body: const Center(
          child: Text('No seat data available', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final rows = seatData.layout.rows;
    final seatsPerRow = seatData.layout.seatsPerRow;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Select Your Seats'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSeatAvailability,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.movieTitle ?? 'Seat Selection',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select Your Seats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatDateTime(seatData.startTime)} • ${seatData.hallName}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              const _ScreenHeader(),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tip: Seats closer to the center usually have the best view.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    const Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _LegendItem(label: 'Available', color: Color(0x1AFFFFFF), border: Color(0x26FFFFFF)),
                        _LegendItem(label: 'Selected', color: Color(0x334ADE80), border: Color(0xAA4ADE80)),
                        _LegendItem(label: 'Booked', color: Color(0x66808080), border: Color(0x99808080)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        children: rows.map((row) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SeatRow(
                              row: row,
                              seatsPerRow: seatsPerRow,
                              selectedSeats: _selectedSeats,
                              bookedSeats: _bookedSet,
                              seatLimitReached: _limitReached,
                              onTapSeat: _toggleSeat,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: Container(height: 1, color: Colors.white12)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('Aisle', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ),
                        Expanded(child: Container(height: 1, color: Colors.white12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Selection',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    if (_selectedSeats.isEmpty)
                      const Text(
                        'No seats selected',
                        style: TextStyle(color: Colors.white70),
                      )
                    else ...[
                      Text(
                        '${_selectedSeats.length} seat(s) - ₹${_totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (_selectedSeats.toList()..sort()).join(', '),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      if (_limitReached)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Seat limit reached. Deselect to choose another.',
                            style: TextStyle(color: Color(0xFFFFD27D), fontSize: 11),
                          ),
                        ),
                    ],
                    const SizedBox(height: 14),
                    _PriceRow(
                      label: 'Price per seat',
                      value: '₹${_pricePerSeat.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 6),
                    _PriceRow(
                      label: 'Total',
                      value: '₹${_totalPrice.toStringAsFixed(0)}',
                      bold: true,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC1121F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _selectedSeats.isEmpty || _booking
                            ? null
                            : _showBookingConfirmation,
                        child: Text(_booking ? 'Processing...' : 'Book Seats'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'or shake the phone',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _selectedSeats.isEmpty ? null : _clearSelectionConfirm,
                        child: const Text('Clear Selection'),
                      ),
                    ),
                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _error,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can change seats before payment confirmation.',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 46,
          width: double.infinity,
          child: CustomPaint(painter: _ScreenArcPainter()),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
          ),
          child: const Text(
            'SCREEN THIS WAY',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScreenArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.5,
        2,
        size.width * 0.92,
        size.height * 0.85,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeatRow extends StatelessWidget {
  const _SeatRow({
    required this.row,
    required this.seatsPerRow,
    required this.selectedSeats,
    required this.bookedSeats,
    required this.seatLimitReached,
    required this.onTapSeat,
  });

  final String row;
  final int seatsPerRow;
  final Set<String> selectedSeats;
  final Set<String> bookedSeats;
  final bool seatLimitReached;
  final ValueChanged<String> onTapSeat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            row,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 10),
        ...List.generate(seatsPerRow, (i) {
          final seatNumber = i + 1;
          final label = '$row$seatNumber';
          final normalized = label.toUpperCase();
          final isBooked = bookedSeats.contains(normalized);
          final isSelected = selectedSeats.contains(normalized);
          final isDisabled = !isSelected && seatLimitReached;
          final isAisle = seatNumber == 7;

          return Row(
            children: [
              if (isAisle)
                Container(
                  width: 10,
                  height: 34,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              _SeatButton(
                label: label,
                selected: isSelected,
                booked: isBooked,
                disabled: isDisabled,
                onTap: () => onTapSeat(label),
              ),
              const SizedBox(width: 6),
            ],
          );
        }),
        const SizedBox(width: 10),
        SizedBox(
          width: 16,
          child: Text(
            row,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _SeatButton extends StatelessWidget {
  const _SeatButton({
    required this.label,
    required this.selected,
    required this.booked,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool booked;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.white.withValues(alpha: 0.15);
    Color background = Colors.white.withValues(alpha: 0.05);
    Color textColor = Colors.white.withValues(alpha: 0.90);

    if (booked) {
      borderColor = Colors.grey.shade600;
      background = Colors.grey.withValues(alpha: 0.32);
      textColor = Colors.white54;
    } else if (selected) {
      borderColor = const Color(0xFF4ADE80);
      background = const Color(0x334ADE80);
      textColor = const Color(0xFFEFFFF5);
    }

    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: booked || (disabled && !selected) ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: disabled && !selected ? 0.55 : 1),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.color,
    required this.border,
  });

  final String label;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
