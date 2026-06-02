import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../movie/movie_details.dart';
import '../../model/movie_model.dart';

const String _kApiKey = '2d688d383e42456bd08cf38e9d73ff22';

enum SeeAllMovieType { popular, topRated, comingSoon }

class SeeAllMoviesScreen extends StatefulWidget {
  final SeeAllMovieType movieType;

  const SeeAllMoviesScreen({super.key, required this.movieType});

  @override
  State<SeeAllMoviesScreen> createState() => _SeeAllMoviesScreenState();
}

class _SeeAllMoviesScreenState extends State<SeeAllMoviesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<MovieModel> _movies = [];
  List<MovieModel> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _hasSearchText = false;
  int _currentPage = 1;
  bool _isFetchingMore = false;
  bool _hasMorePages = true;

  // Helpers

  String get _endpoint {
    switch (widget.movieType) {
      case SeeAllMovieType.popular:
        return 'popular';
      case SeeAllMovieType.topRated:
        return 'top_rated';
      case SeeAllMovieType.comingSoon:
        return 'upcoming';
    }
  }

  String get _title {
    switch (widget.movieType) {
      case SeeAllMovieType.popular:
        return 'Popular Now';
      case SeeAllMovieType.topRated:
        return 'Top Rated';
      case SeeAllMovieType.comingSoon:
        return 'Coming Soon';
    }
  }

  Color get _accentColor {
    switch (widget.movieType) {
      case SeeAllMovieType.popular:
        return const Color(0xFFE50914);
      case SeeAllMovieType.topRated:
        return const Color(0xFFFFB800);
      case SeeAllMovieType.comingSoon:
        return const Color(0xFF4A80F0);
    }
  }

  IconData get _icon {
    switch (widget.movieType) {
      case SeeAllMovieType.popular:
        return Icons.local_fire_department_rounded;
      case SeeAllMovieType.topRated:
        return Icons.star_rounded;
      case SeeAllMovieType.comingSoon:
        return Icons.calendar_month_rounded;
    }
  }

  Uri _buildUri(int page) => Uri.parse(
    'https://api.themoviedb.org/3/movie/$_endpoint'
    '?api_key=$_kApiKey&language=en-US&page=$page',
  );

  // Lifecycle

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll / Pagination

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isFetchingMore &&
        _hasMorePages &&
        !_hasSearchText) {
      _fetchMoreMovies();
    }
  }

  // Data fetching

  Future<void> _fetchMovies() async {
    try {
      final res = await http.get(_buildUri(1));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List results = data['results'];
        if (mounted) {
          setState(() {
            _movies = results.map((e) => MovieModel.fromJson(e)).toList();
            _isLoading = false;
            _currentPage = 1;
            _hasMorePages = (data['total_pages'] ?? 1) > 1;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreMovies() async {
    if (_isFetchingMore) return;
    setState(() => _isFetchingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final res = await http.get(_buildUri(nextPage));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List results = data['results'];
        if (mounted) {
          setState(() {
            _movies.addAll(results.map((e) => MovieModel.fromJson(e)).toList());
            _currentPage = nextPage;
            _isFetchingMore = false;
            _hasMorePages = nextPage < (data['total_pages'] ?? 1);
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  // Search

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    setState(() => _hasSearchText = q.isNotEmpty);
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    _searchMovies(q);
  }

  Future<void> _searchMovies(String query) async {
    setState(() => _isSearching = true);
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/search/movie'
          '?api_key=$_kApiKey&language=en-US'
          '&query=${Uri.encodeComponent(query)}&page=1',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List results = data['results'];
        if (mounted) {
          setState(() {
            _searchResults = results
                .map((e) => MovieModel.fromJson(e))
                .toList();
            _isSearching = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.unfocus();
  }

  // Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 24),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // Header

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 13),

          Row(
            children: [
              Icon(_icon, color: _accentColor, size: 25),
              const SizedBox(width: 5),
              Text(
                _title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Search bar

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focusNode.hasFocus
                ? _accentColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search $_title movies...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onTap: () => setState(() {}),
              ),
            ),
            if (_hasSearchText)
              GestureDetector(
                onTap: _clearSearch,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  // Body

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
      );
    }
    if (_hasSearchText) return _buildSearchGrid();
    return _buildMoviesGrid();
  }

  Widget _buildMoviesGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: _movies.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _movies.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: _accentColor,
                strokeWidth: 2,
              ),
            ),
          );
        }
        return _MovieGridCard(movie: _movies[index]);
      },
    );
  }

  Widget _buildSearchGrid() {
    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
      );
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: Colors.white.withValues(alpha: 0.2),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No movies found',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) =>
          _MovieGridCard(movie: _searchResults[index]),
    );
  }
}

// Movie Grid Card

class _MovieGridCard extends StatelessWidget {
  final MovieModel movie;

  const _MovieGridCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => MovieDetails(movieModel: movie),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  movie.posterPath != null
                      ? Image.network(
                          'https://image.tmdb.org/t/p/w300${movie.posterPath}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                  // Bottom gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Rating badge
                  if (movie.voteAverage != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            movie.voteAverage!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          if (movie.releaseDate != null && movie.releaseDate!.length >= 4)
            Text(
              movie.releaseDate!.substring(0, 4),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF1A1A28),
      child: const Center(
        child: Icon(Icons.movie_outlined, color: Color(0xFF3A3A50), size: 32),
      ),
    );
  }
}
