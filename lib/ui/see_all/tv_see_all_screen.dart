import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../model/tv_model.dart';
import '../tv/tv_details.dart';

const String _kTvSeeAllApiKey = '2d688d383e42456bd08cf38e9d73ff22';

enum SeeAllTvType { popular, topRated, onTheAir }

class TVSeeAllScreen extends StatefulWidget {
  final SeeAllTvType tvType;

  const TVSeeAllScreen({super.key, required this.tvType});

  @override
  State<TVSeeAllScreen> createState() => _TVSeeAllScreenState();
}

class _TVSeeAllScreenState extends State<TVSeeAllScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<TVModel> _shows = [];
  List<TVModel> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _hasSearchText = false;
  int _currentPage = 1;
  bool _isFetchingMore = false;
  bool _hasMorePages = true;

  // Helpers

  String get _endpoint {
    switch (widget.tvType) {
      case SeeAllTvType.popular:
        return 'popular';
      case SeeAllTvType.topRated:
        return 'top_rated';
      case SeeAllTvType.onTheAir:
        return 'on_the_air';
    }
  }

  String get _title {
    switch (widget.tvType) {
      case SeeAllTvType.popular:
        return 'Popular Shows';
      case SeeAllTvType.topRated:
        return 'Top Rated';
      case SeeAllTvType.onTheAir:
        return 'On The Air';
    }
  }

  Color get _accentColor {
    switch (widget.tvType) {
      case SeeAllTvType.popular:
        return const Color(0xFF00D4C8);
      case SeeAllTvType.topRated:
        return const Color(0xFFFFB800);
      case SeeAllTvType.onTheAir:
        return const Color(0xFF4ACA6A);
    }
  }

  IconData get _icon {
    switch (widget.tvType) {
      case SeeAllTvType.popular:
        return Icons.local_fire_department_rounded;
      case SeeAllTvType.topRated:
        return Icons.star_rounded;
      case SeeAllTvType.onTheAir:
        return Icons.sensors_rounded;
    }
  }

  Uri _buildUri(int page) => Uri.parse(
    'https://api.themoviedb.org/3/tv/$_endpoint'
    '?api_key=$_kTvSeeAllApiKey&language=en-US&page=$page',
  );

  // Lifecycle

  @override
  void initState() {
    super.initState();
    _fetchShows();
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
      _fetchMoreShows();
    }
  }

  // Data fetching

  Future<void> _fetchShows() async {
    try {
      final res = await http.get(_buildUri(1));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List results = data['results'];
        if (mounted) {
          setState(() {
            _shows = results.map((e) => TVModel.fromJson(e)).toList();
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

  Future<void> _fetchMoreShows() async {
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
            _shows.addAll(results.map((e) => TVModel.fromJson(e)).toList());
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
    _searchShows(q);
  }

  Future<void> _searchShows(String query) async {
    setState(() => _isSearching = true);
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/search/tv'
          '?api_key=$_kTvSeeAllApiKey&language=en-US'
          '&query=${Uri.encodeComponent(query)}&page=1',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List results = data['results'];
        if (mounted) {
          setState(() {
            _searchResults = results.map((e) => TVModel.fromJson(e)).toList();
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
                  hintText: 'Search $_title...',
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
    return _buildShowsGrid();
  }

  Widget _buildShowsGrid() {
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
      itemCount: _shows.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _shows.length) {
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
        return _TVGridCard(show: _shows[index]);
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
              'No shows found',
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
      itemBuilder: (context, index) => _TVGridCard(show: _searchResults[index]),
    );
  }
}

// TV Grid Card

class _TVGridCard extends StatelessWidget {
  final TVModel show;

  const _TVGridCard({required this.show});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => TVDetails(tvModel: show),
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
                  show.posterPath != null
                      ? Image.network(
                          'https://image.tmdb.org/t/p/w300${show.posterPath}',
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
                  if (show.voteAverage != null)
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
                            show.voteAverage!.toStringAsFixed(1),
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
            show.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          if (show.firstAirDate != null && show.firstAirDate!.length >= 4)
            Text(
              show.firstAirDate!.substring(0, 4),
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
        child: Icon(Icons.tv_outlined, color: Color(0xFF3A3A50), size: 32),
      ),
    );
  }
}
