import 'package:flutter/material.dart';
import 'package:ceniflix/core/api/api_client.dart';
import 'package:ceniflix/features/bottom_screens/data/datasources/remote/movie_remote_datasource.dart';
import 'package:ceniflix/features/bottom_screens/data/models/movie_api_model.dart';
import 'package:ceniflix/features/seats/data/datasources/remote/booking_remote_datasource.dart';
import 'package:ceniflix/features/seats/data/models/showtime_api_model.dart';
import '../../../seats/presentation/pages/seats.dart';
import 'package:dio/dio.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  late final MovieRemoteDataSource _movieRemoteDataSource;
  late final BookingRemoteDataSource _bookingRemoteDataSource;
  late final Future<List<MovieApiModel>> _nowShowingFuture;
  late final Future<List<MovieApiModel>> _comingSoonFuture;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _movieRemoteDataSource = MovieRemoteDataSource(apiClient);
    _bookingRemoteDataSource = BookingRemoteDataSource(apiClient);
    _nowShowingFuture = _movieRemoteDataSource.getNowShowingMovies();
    _comingSoonFuture = _movieRemoteDataSource.getComingSoonMovies();
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

  String _formatShowtime(DateTime? value) {
    if (value == null) return 'Time not available';
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _openShowtimePicker(MovieApiModel movie) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: FutureBuilder<List<ShowtimeApiModel>>(
            future: _bookingRemoteDataSource.getShowtimesByMovie(movie.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                final errorText = snapshot.error is DioException
                    ? _extractApiError(
                        snapshot.error as DioException,
                        fallback: 'Failed to load showtimes',
                      )
                    : 'Failed to load showtimes';

                return SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      errorText,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final showtimes = snapshot.data ?? const <ShowtimeApiModel>[];
              if (showtimes.isEmpty) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'No showtimes available',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select a showtime',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: showtimes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final showtime = showtimes[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(this.context).push(
                              MaterialPageRoute(
                                builder: (_) => SeatsScreen(
                                  showtimeId: showtime.id,
                                  movieTitle: movie.title,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.13),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, color: Colors.white70, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${_formatShowtime(showtime.startTime)} • ${showtime.hallName}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${showtime.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showMovieDetails(
    BuildContext context, {
    required MovieApiModel movie,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _posterImage(
                        movie.imageUrl,
                        height: 180,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      movie.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.genreLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          movie.duration,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          movie.scoreLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      movie.synopsis,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF233C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openShowtimePicker(movie);
                        },
                        child: const Text(
                          "Book Ticket",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _posterImage(String? imageUrl, {double? width, double? height}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.black26,
        child: const Icon(Icons.movie, color: Colors.white70),
      );
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          width: width,
          height: height,
          color: Colors.black26,
          child: const Icon(Icons.broken_image, color: Colors.white70),
        );
      },
    );
  }

  Widget _movieCard({
    required MovieApiModel movie,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: _posterImage(
                movie.imageUrl,
                width: 110,
                height: 150,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.genreLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          movie.duration,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          movie.scoreLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: FutureBuilder<List<List<MovieApiModel>>>(
        future: Future.wait([
          _nowShowingFuture,
          _comingSoonFuture,
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load movies: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final nowShowingMovies = snapshot.data?[0] ?? const <MovieApiModel>[];
          final comingSoonMovies = snapshot.data?[1] ?? const <MovieApiModel>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Now Showing',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: nowShowingMovies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final movie = nowShowingMovies[index];
                    return _movieCard(
                      movie: movie,
                      onTap: () => _showMovieDetails(context, movie: movie),
                    );
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comingSoonMovies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final movie = comingSoonMovies[index];
                    return _movieCard(
                      movie: movie,
                      onTap: () => _showMovieDetails(context, movie: movie),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
