import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../movie/movie_details.dart';
import '../../model/movie_model.dart';
import 'movie_genres_screen.dart';

const String _kGenreApiKey = '2d688d383e42456bd08cf38e9d73ff22';

class GenreDetailsScreen extends StatefulWidget {
  final GenreModel genre;
  final List<GenreModel> allGenres;

  const GenreDetailsScreen({
    super.key,
    required this.genre,
    required this.allGenres,
  });

  @override
  State<GenreDetailsScreen> createState() => _GenreDetailsScreenState();
}

class _GenreDetailsScreenState extends State<GenreDetailsScreen> {
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

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isFetchingMore &&
        _hasMorePages &&
        !_hasSearchText) {
      _fetchMoreMovies();
    }
  }

  Future<void> _fetchMovies() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/discover/movie?api_key=$_kGenreApiKey&language=en-US&sort_by=popularity.desc&with_genres=${widget.genre.id}&page=1',
        ),
      );
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
      final res = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/discover/movie?api_key=$_kGenreApiKey&language=en-US&sort_by=popularity.desc&with_genres=${widget.genre.id}&page=$nextPage',
        ),
      );
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
    _searchInGenre(q);
  }

  Future<void> _searchInGenre(String query) async {
    setState(() => _isSearching = true);
    try {
      // Search movies within this specific genre only
      final res = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/search/movie?api_key=$_kGenreApiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List results = data['results'];
        // Filter to only include movies with this genre id
        final filtered = results
            .map((e) => MovieModel.fromJson(e))
            .where(
              (m) =>
                  m.genreIds != null && m.genreIds!.contains(widget.genre.id),
            )
            .toList();
        if (mounted) {
          setState(() {
            _searchResults = filtered;
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

  // accent color per genre (same index logic as genre grid)
  Color _accentColor() {
    switch (widget.genre.name.toLowerCase()) {
      case 'action':
        return const Color(0xFFE55050);
      case 'adventure':
        return const Color(0xFF4ACA6A);
      case 'animation':
        return const Color(0xFF4A80F0);
      case 'comedy':
        return const Color(0xFFE0A020);
      case 'crime':
        return const Color(0xFF9A6AF0);
      case 'documentary':
        return const Color(0xFF30C0E5);
      case 'drama':
        return const Color(0xFFD060E0);
      case 'family':
        return const Color(0xFF4ACA6A);
      case 'fantasy':
        return const Color(0xFF9A6AF0);
      case 'history':
        return const Color(0xFFE0A020);
      case 'horror':
        return const Color(0xFFE55050);
      case 'music':
        return const Color(0xFF30C0E5);
      case 'mystery':
        return const Color(0xFF4A80F0);
      case 'romance':
        return const Color(0xFFE55050);
      case 'science fiction':
        return const Color(0xFF4A80F0);
      case 'thriller':
        return const Color(0xFF9A6AF0);
      case 'war':
        return const Color(0xFFE0A020);
      case 'western':
        return const Color(0xFFE0A020);
      default:
        return const Color(0xFFE50914);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(accent),
            _buildSearchBar(accent),
            const SizedBox(height: 24),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
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
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 22,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.genre.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Sorted by popularity',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focusNode.hasFocus
                ? accent.withValues(alpha: 0.5)
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
                  hintText: 'Search ${widget.genre.name} movies...',
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

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: _accentColor(), strokeWidth: 2),
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
                color: _accentColor(),
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
        child: CircularProgressIndicator(color: _accentColor(), strokeWidth: 2),
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
              'No ${widget.genre.name} movies found',
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
