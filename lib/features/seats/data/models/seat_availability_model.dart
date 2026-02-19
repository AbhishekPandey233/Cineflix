class SeatLayoutModel {
  final List<String> rows;
  final int seatsPerRow;
  final List<String> seatIds;

  const SeatLayoutModel({
    required this.rows,
    required this.seatsPerRow,
    required this.seatIds,
  });

  factory SeatLayoutModel.fromJson(Map<String, dynamic> json) {
    final rawRows = json['rows'];
    final rawSeatIds = json['seatIds'];

    return SeatLayoutModel(
      rows: rawRows is List ? rawRows.map((e) => e.toString()).toList() : const [],
      seatsPerRow: int.tryParse((json['seatsPerRow'] ?? '').toString()) ?? 0,
      seatIds: rawSeatIds is List
          ? rawSeatIds.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

class SeatAvailabilityModel {
  final String showtimeId;
  final String movieId;
  final String hallId;
  final String hallName;
  final DateTime? startTime;
  final double price;
  final SeatLayoutModel layout;
  final List<String> bookedSeats;

  const SeatAvailabilityModel({
    required this.showtimeId,
    required this.movieId,
    required this.hallId,
    required this.hallName,
    required this.startTime,
    required this.price,
    required this.layout,
    required this.bookedSeats,
  });

  factory SeatAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final rawBooked = json['bookedSeats'];

    return SeatAvailabilityModel(
      showtimeId: (json['showtimeId'] ?? '').toString(),
      movieId: (json['movieId'] ?? '').toString(),
      hallId: (json['hallId'] ?? '').toString(),
      hallName: (json['hallName'] ?? '').toString(),
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString())
          : null,
      price: double.tryParse((json['price'] ?? '').toString()) ?? 0,
      layout: SeatLayoutModel.fromJson(
        (json['layout'] is Map<String, dynamic>)
            ? json['layout'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
      bookedSeats: rawBooked is List
          ? rawBooked.map((e) => e.toString().toUpperCase()).toList()
          : const [],
    );
  }
}
