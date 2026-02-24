import 'package:flutter/material.dart';
import 'package:ceniflix/core/api/api_client.dart';
import 'package:ceniflix/features/bottom_screens/data/datasources/remote/movie_remote_datasource.dart';
import 'package:ceniflix/features/bottom_screens/data/models/movie_api_model.dart';
import '../../../bottom_screens/presentation/pages/movies_screen.dart';
import '../../../bottom_screens/presentation/pages/profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePageBody(onOpenMovies: () => _openTab(1)),
      const MoviesScreen(),
      const ProfileScreen(),
    ];
  }

  void _openTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/cineflixlogo.PNG',
              height: 26,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              "CineFlix",
              style: TextStyle(
                color: Color(0xFFEF233C),
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0D0D0D),
        selectedItemColor: const Color(0xFFEF233C),
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        onTap: _openTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Movies'),
          BottomNavigationBarItem(icon: Icon(Icons.man_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key, required this.onOpenMovies});

  final VoidCallback onOpenMovies;

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  late final MovieRemoteDataSource _movieRemoteDataSource;
  late final Future<List<MovieApiModel>> _nowShowingFuture;
  late final Future<List<MovieApiModel>> _comingSoonFuture;

  @override
  void initState() {
    super.initState();
    _movieRemoteDataSource = MovieRemoteDataSource(ApiClient());
    _nowShowingFuture = _movieRemoteDataSource.getNowShowingMovies();
    _comingSoonFuture = _movieRemoteDataSource.getComingSoonMovies();
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

  Widget _moviePoster(BuildContext context, MovieApiModel movie) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onOpenMovies,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              _posterImage(movie.imageUrl, width: 160, height: 220),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    movie.rating.isEmpty ? 'PG-13' : movie.rating,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recommendedCard({
    required String? poster,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _posterImage(poster, width: 130, height: 160),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<MovieApiModel>>>(
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

        final nowShowing = snapshot.data?[0] ?? const <MovieApiModel>[];
        final comingSoon = snapshot.data?[1] ?? const <MovieApiModel>[];
        final allMovies = [...nowShowing, ...comingSoon];
        final popular = allMovies.where((movie) {
          final title = movie.title.toLowerCase();
          return title.contains('avatar 3') || title.contains('avengers');
        }).toList()
          ..sort((a, b) {
            int rank(String title) {
              final lower = title.toLowerCase();
              if (lower.contains('avatar 3')) return 0;
              if (lower.contains('avengers')) return 1;
              return 2;
            }

            return rank(a.title).compareTo(rank(b.title));
          });

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x22EF233C),
                      Color(0x00000000),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Divider(color: Color(0xFFEF233C), thickness: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'NOW IN CINEMAS',
                          style: TextStyle(
                            color: Color(0xFFEF233C),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'New Movies,',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'BlockBusters!!',
                      style: TextStyle(
                        color: Color(0xFFEF233C),
                        fontSize: 48,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Book anywhere. Cancel anytime. Experience cinema like never before with CineFlix premium seating.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF233C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: widget.onOpenMovies,
                        child: const Text(
                          'BOOK TICKETS NOW',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Text(
                    'Now Showing',
                    style: TextStyle(
                      color: Color(0xFFEF233C),
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onOpenMovies,
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: nowShowing.length,
                  itemBuilder: (context, index) {
                    return _moviePoster(context, nowShowing[index]);
                  },
                ),
              ),

              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onOpenMovies,
                    child: const Text(
                      'See All >',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: popular.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final movie = popular[i];
                    return _recommendedCard(
                      poster: movie.imageUrl,
                      title: movie.title,
                      subtitle: movie.genreLabel,
                      onTap: widget.onOpenMovies,
                    );
                  },
                ),
              ),

              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Coming Soon',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onOpenMovies,
                    child: const Text(
                      'See All >',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: comingSoon.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final movie = comingSoon[i];
                    return _recommendedCard(
                      poster: movie.imageUrl,
                      title: movie.title,
                      subtitle: 'Coming Soon',
                      onTap: widget.onOpenMovies,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
