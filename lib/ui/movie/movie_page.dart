import 'package:flutter/material.dart';
import '/service/api_service.dart';
import '/ui/movie/movies_category.dart';
import '../../model/movie_model.dart';
import 'components/movie_carousel.dart';
import '../genres/movie_genres_screen.dart';
import '../search/movie_search_screen.dart';
import '../see_all/see_all_movies_screen.dart';

class MoviePage extends StatefulWidget {
  const MoviePage({super.key});

  @override
  State<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends State<MoviePage> {
  final ApiService apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final opacity = (_scrollController.offset / 200).clamp(0.0, 1.0);
      if ((opacity - _appBarOpacity).abs() > 0.01) {
        setState(() => _appBarOpacity = opacity);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToSeeAll(SeeAllMovieType type) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SeeAllMoviesScreen(movieType: type),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: const Color(0xFF0A0A0F).withValues(alpha: _appBarOpacity),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Logo / App name
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'CINE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        TextSpan(
                          text: 'VAULT',
                          style: TextStyle(
                            color: Color(0xFFE50914),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Search button
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const SearchScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Genre button
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const GenresScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 350),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Carousel
          SliverToBoxAdapter(
            child: FutureBuilder(
              future: apiService.getMovieData(MovieType.nowPlaying),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<MovieModel> movies = snapshot.data ?? [];
                  return MovieCarousel(movieModelList: movies);
                }
                return const SizedBox(
                  height: 480,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE50914),
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
            ),
          ),

          // Sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _SectionHeader(
                    title: 'Popular Now',
                    icon: Icons.local_fire_department_rounded,
                    onSeeAll: () => _goToSeeAll(SeeAllMovieType.popular),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 210,
                    child: MoviesCategory(movieType: MovieType.popular),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Top Rated',
                    icon: Icons.star_rounded,
                    onSeeAll: () => _goToSeeAll(SeeAllMovieType.topRated),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 210,
                    child: MoviesCategory(movieType: MovieType.topRated),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Coming Soon',
                    icon: Icons.calendar_month_rounded,
                    onSeeAll: () => _goToSeeAll(SeeAllMovieType.comingSoon),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 210,
                    child: MoviesCategory(movieType: MovieType.upcoming),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE50914), size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  'See all',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
