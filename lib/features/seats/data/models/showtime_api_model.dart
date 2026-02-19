class ShowtimeApiModel {
  final String id;
  final String movieId;
  final String hallId;
  final String hallName;
  final DateTime? startTime;
  final double price;

  const ShowtimeApiModel({
    required this.id,
    required this.movieId,
    required this.hallId,
    required this.hallName,
    required this.startTime,
    required this.price,
  });

  factory ShowtimeApiModel.fromJson(Map<String, dynamic> json) {
    return ShowtimeApiModel(
      id: (json['_id'] ?? '').toString(),
      movieId: (json['movieId'] ?? '').toString(),
      hallId: (json['hallId'] ?? '').toString(),
      hallName: (json['hallName'] ?? '').toString(),
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString())
          : null,
      price: double.tryParse((json['price'] ?? '').toString()) ?? 0,
    );
  }
}
