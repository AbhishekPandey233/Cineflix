import 'package:ceniflix/core/api/api_endpoint.dart';
import 'package:ceniflix/features/bottom_screens/data/models/movie_api_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
	test('MovieApiModel.fromJson(): parses valid values correctly', () {
		final json = {
			'_id': 'm1',
			'title': 'Avatar 3',
			'genre': 'Sci-Fi',
			'rating': 'PG-13',
			'img': '/uploads/avatar3.jpg',
			'year': 2026,
			'score': 8.3,
			'duration': '2h 45m',
			'synopsis': 'A sci-fi adventure.',
			'language': 'English',
			'status': 'now_showing',
			'releaseDate': '2026-12-01T00:00:00.000Z',
		};

		final movie = MovieApiModel.fromJson(json);

		expect(movie.id, 'm1');
		expect(movie.title, 'Avatar 3');
		expect(movie.genre, 'Sci-Fi');
		expect(movie.rating, 'PG-13');
		expect(movie.year, 2026);
		expect(movie.score, 8.3);
		expect(movie.releaseDate, isNotNull);
	});

	test('MovieApiModel.fromJson(): falls back to defaults for invalid values', () {
		final json = {
			'_id': null,
			'title': null,
			'genre': null,
			'rating': null,
			'img': null,
			'year': 'invalid',
			'score': 'invalid',
			'duration': null,
			'synopsis': null,
			'language': null,
			'status': null,
			'releaseDate': 'not-a-date',
		};

		final movie = MovieApiModel.fromJson(json);

		expect(movie.id, '');
		expect(movie.title, '');
		expect(movie.year, 0);
		expect(movie.score, 0);
		expect(movie.imageUrl, isNull);
		expect(movie.releaseDate, isNull);
	});

	test('MovieApiModel.imageUrl: returns null when image is empty', () {
		final movie = MovieApiModel.fromJson({
			'_id': 'm2',
			'title': 'No Image',
			'genre': 'Drama',
			'rating': 'PG',
			'img': '',
			'year': 2025,
			'score': 7.2,
			'duration': '2h',
			'synopsis': 'No image movie',
			'language': 'English',
			'status': 'coming_soon',
			'releaseDate': null,
		});

		expect(movie.imageUrl, isNull);
	});

	test('MovieApiModel.imageUrl: converts local path to server URL', () {
		final movie = MovieApiModel.fromJson({
			'_id': 'm3',
			'title': 'Local Path',
			'genre': 'Action',
			'rating': 'PG-13',
			'img': '/uploads/local.jpg',
			'year': 2026,
			'score': 8.0,
			'duration': '2h 10m',
			'synopsis': 'Local path image.',
			'language': 'English',
			'status': 'now_showing',
			'releaseDate': null,
		});

		expect(movie.imageUrl, '${ApiEndpoints.serverUrl}/uploads/local.jpg');
	});

	test('MovieApiModel.imageUrl: keeps non-localhost absolute URL unchanged', () {
		final image = 'https://cdn.example.com/poster.jpg';
		final movie = MovieApiModel.fromJson({
			'_id': 'm4',
			'title': 'Remote URL',
			'genre': 'Adventure',
			'rating': 'PG-13',
			'img': image,
			'year': 2027,
			'score': 8.8,
			'duration': '2h 20m',
			'synopsis': 'Remote image.',
			'language': 'English',
			'status': 'coming_soon',
			'releaseDate': null,
		});

		expect(movie.imageUrl, image);
	});

	test('MovieApiModel.imageUrl: rewrites localhost URL to server URL', () {
		final movie = MovieApiModel.fromJson({
			'_id': 'm5',
			'title': 'Localhost URL',
			'genre': 'Action',
			'rating': 'R',
			'img': 'http://localhost:5000/uploads/localhost.jpg',
			'year': 2027,
			'score': 9.1,
			'duration': '2h 30m',
			'synopsis': 'Localhost image.',
			'language': 'English',
			'status': 'now_showing',
			'releaseDate': null,
		});

		expect(movie.imageUrl, '${ApiEndpoints.serverUrl}/uploads/localhost.jpg');
	});

	test('MovieApiModel labels: genreLabel and scoreLabel are formatted', () {
		final movie = MovieApiModel.fromJson({
			'_id': 'm6',
			'title': 'Labels',
			'genre': 'Thriller',
			'rating': 'PG-13',
			'img': '/uploads/labels.jpg',
			'year': 2026,
			'score': 8,
			'duration': '2h 05m',
			'synopsis': 'Label checks.',
			'language': 'English',
			'status': 'now_showing',
			'releaseDate': null,
		});

		expect(movie.genreLabel, 'Thriller');
		expect(movie.scoreLabel, '8.0');
	});
}
