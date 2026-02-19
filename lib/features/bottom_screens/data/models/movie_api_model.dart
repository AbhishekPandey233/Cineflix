import 'package:ceniflix/core/api/api_endpoint.dart';

class MovieApiModel {
  final String id;
  final String title;
  final String genre;
  final String rating;
  final String? img;
  final int year;
  final double score;
  final String duration;
  final String synopsis;
  final String language;
  final String status;
  final DateTime? releaseDate;

  MovieApiModel({
    required this.id,
    required this.title,
    required this.genre,
    required this.rating,
    required this.img,
    required this.year,
    required this.score,
    required this.duration,
    required this.synopsis,
    required this.language,
    required this.status,
    required this.releaseDate,
  });

  factory MovieApiModel.fromJson(Map<String, dynamic> json) {
    return MovieApiModel(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      genre: (json['genre'] ?? '').toString(),
      rating: (json['rating'] ?? '').toString(),
      img: json['img']?.toString(),
      year: int.tryParse((json['year'] ?? '').toString()) ?? 0,
      score: double.tryParse((json['score'] ?? '').toString()) ?? 0,
      duration: (json['duration'] ?? '').toString(),
      synopsis: (json['synopsis'] ?? '').toString(),
      language: (json['language'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      releaseDate: json['releaseDate'] != null
          ? DateTime.tryParse(json['releaseDate'].toString())
          : null,
    );
  }

  String? get imageUrl {
    if (img == null || img!.isEmpty) return null;

    final imagePath = img!;

    if (imagePath.startsWith('http')) {
      if (imagePath.contains('localhost:5000') || imagePath.contains('127.0.0.1:5000')) {
        try {
          final uri = Uri.parse(imagePath);
          return '${ApiEndpoints.serverUrl}${uri.path}';
        } catch (_) {
          return imagePath
              .replaceAll('http://localhost:5000', ApiEndpoints.serverUrl)
              .replaceAll('http://127.0.0.1:5000', ApiEndpoints.serverUrl);
        }
      }
      return imagePath;
    }

    if (imagePath.startsWith('/')) {
      return '${ApiEndpoints.serverUrl}$imagePath';
    }

    return '${ApiEndpoints.serverUrl}/$imagePath';
  }

  String get genreLabel => genre;
  String get scoreLabel => score.toStringAsFixed(1);
}
