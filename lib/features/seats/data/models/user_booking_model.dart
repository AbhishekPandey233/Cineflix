class UserBookingModel {
  final String id;
  final String showtimeId;
  final String movieId;
  final String movieTitle;
  final String hallId;
  final String hallName;
  final DateTime? startTime;
  final double price;
  final List<String> seats;
  final double totalPrice;
  final String status;
  final String paymentStatus;
  final String paymentProvider;
  final bool isPaid;
  final String? paymentReference;
  final String? canceledBy;
  final DateTime? createdAt;

  const UserBookingModel({
    required this.id,
    required this.showtimeId,
    required this.movieId,
    required this.movieTitle,
    required this.hallId,
    required this.hallName,
    required this.startTime,
    required this.price,
    required this.seats,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    required this.paymentProvider,
    required this.isPaid,
    required this.paymentReference,
    required this.canceledBy,
    required this.createdAt,
  });

  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get requiresPayment => !isPaid && status.toLowerCase() != 'cancelled';

  factory UserBookingModel.fromJson(Map<String, dynamic> json) {
    final showtime = json['showtimeId'];
    final showtimeMap = showtime is Map<String, dynamic>
        ? showtime
        : <String, dynamic>{};

    final movie = showtimeMap['movieId'];
    final movieMap = movie is Map<String, dynamic> ? movie : <String, dynamic>{};

    final rawSeats = json['seats'];
    final payment = json['payment'];
    final paymentMap = payment is Map<String, dynamic>
      ? payment
      : <String, dynamic>{};

    final rawPaymentStatus =
      paymentMap['status'] ?? json['paymentStatus'] ?? json['payment_state'];
    final parsedPaymentStatus = (rawPaymentStatus ?? '').toString().toLowerCase();

    final rawPaymentProvider =
        paymentMap['provider'] ?? json['paymentProvider'] ?? json['paymentMethod'];

    final rawIsPaid = json['isPaid'] ?? paymentMap['isPaid'] ?? json['paid'];
    final parsedIsPaid =
      rawIsPaid == true ||
      rawIsPaid?.toString().toLowerCase() == 'true' ||
      rawIsPaid?.toString() == '1' ||
      const {'paid', 'completed', 'complete', 'success', 'succeeded'}
        .contains(parsedPaymentStatus);

    return UserBookingModel(
      id: (json['_id'] ?? '').toString(),
      showtimeId: (showtimeMap['_id'] ?? '').toString(),
      movieId: (movieMap['_id'] ?? '').toString(),
      movieTitle: (movieMap['title'] ?? 'Unknown Movie').toString(),
      hallId: (showtimeMap['hallId'] ?? '').toString(),
      hallName: (showtimeMap['hallName'] ?? '').toString(),
      startTime: showtimeMap['startTime'] != null
          ? DateTime.tryParse(showtimeMap['startTime'].toString())
          : null,
      price: double.tryParse((showtimeMap['price'] ?? '').toString()) ?? 0,
      seats: rawSeats is List ? rawSeats.map((e) => e.toString()).toList() : const [],
      totalPrice: double.tryParse((json['totalPrice'] ?? '').toString()) ?? 0,
      status: (json['status'] ?? '').toString(),
        paymentStatus: parsedPaymentStatus,
        paymentProvider: (rawPaymentProvider ?? '').toString(),
        isPaid: parsedIsPaid,
        paymentReference: (paymentMap['pidx'] ??
            paymentMap['transactionId'] ??
            json['khaltiPidx'] ??
            json['paymentReference'])
          ?.toString(),
      canceledBy: json['canceledBy']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
