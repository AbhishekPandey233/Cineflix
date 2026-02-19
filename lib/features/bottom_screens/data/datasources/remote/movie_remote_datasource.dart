import 'package:ceniflix/core/api/api_client.dart';
import 'package:ceniflix/core/api/api_endpoint.dart';
import 'package:ceniflix/features/bottom_screens/data/models/movie_api_model.dart';

class MovieRemoteDataSource {
  MovieRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<MovieApiModel>> getNowShowingMovies() async {
    final response = await _apiClient.get(ApiEndpoints.nowShowingMovies);
    return _parseMovies(response.data);
  }

  Future<List<MovieApiModel>> getComingSoonMovies() async {
    final response = await _apiClient.get(ApiEndpoints.comingSoonMovies);
    return _parseMovies(response.data);
  }

  Future<List<MovieApiModel>> getAllMovies() async {
    final response = await _apiClient.get(ApiEndpoints.movies);
    return _parseMovies(response.data);
  }

  List<MovieApiModel> _parseMovies(dynamic body) {
    final root = body is Map<String, dynamic> ? body : <String, dynamic>{};
    final rawList = root['data'];

    if (rawList is! List) return [];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(MovieApiModel.fromJson)
        .toList();
  }
}
