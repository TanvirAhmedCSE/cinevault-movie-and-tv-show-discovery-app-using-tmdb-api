import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'tv_all_genres_details_screen.dart';
import 'tv_genre_details_screen.dart';
import '../tv/tv_details.dart';
import '../../model/tv_model.dart';

const String _kTvGenreApiKey = '2d688d383e42456bd08cf38e9d73ff22';
const Color _kTvAccent = Color(0xFF00D4C8);

class TVGenreModel {
  final int id;
  final String name;

  const TVGenreModel({required this.id, required this.name});
}

class TVGenresScreen extends StatefulWidget {
  const TVGenresScreen({super.key});

  @override
  State<TVGenresScreen> createState() => _TVGenresScreenState();
}

class _TVGenresScreenState extends State<TVGenresScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<TVGenreModel> _allGenres = [];
  List<TVGenreModel> _filteredGenres = [];
  List<TVModel> _searchedShows = [];
  bool _isLoadingGenres = true;
  bool _isSearching = false;
  bool _hasSearchText = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchGenres();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchGenres() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/genre/tv/list?api_key=$_kTvGenreApiKey&language=en-US',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List genres = data['genres'];
        final list = genres
            .map((g) => TVGenreModel(id: g['id'], name: g['name']))
            .toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        if (mounted) {
          setState(() {
            _allGenres = list;
            _filteredGenres = list;
            _isLoadingGenres = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGenres = false);
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    setState(() {
      _searchQuery = q;
      _hasSearchText = q.isNotEmpty;
    });
    if (q.isEmpty) {
      setState(() {
        _filteredGenres = _allGenres;
        _searchedShows = [];
        _isSearching = false;
      });
      return;
    }

    final matchedGenres = _allGenres
        .where((g) => g.name.toLowerCase().contains(q.toLowerCase()))
        .toList();
    setState(() => _filteredGenres = matchedGenres);

    _searchShows(q);
  }

  Future<void> _searchShows(String query) async {
    setState(() => _isSearching = true);
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/search/tv?api_key=$_kTvGenreApiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List results = data['results'];
        if (mounted) {
          setState(() {
            _searchedShows = results.map((e) => TVModel.fromJson(e)).toList();
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
            Expanded(
              child: _hasSearchText
                  ? _buildSearchResults()
                  : _buildGenresGrid(),
            ),
          ],
        ),
      ),
    );
  }

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
          const SizedBox(width: 16),
          const Text(
            'Genres',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

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
                ? _kTvAccent.withValues(alpha: 0.5)
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
                  hintText: 'Search genres or TV shows...',
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

  Widget _buildGenresGrid() {
    if (_isLoadingGenres) {
      return const Center(
        child: CircularProgressIndicator(color: _kTvAccent, strokeWidth: 2),
      );
    }

    final allItem = _TVGenreGridItem(
      label: 'All',
      icon: Icons.tv_rounded,
      isAll: true,
      index: 0,
      onTap: () => Navigator.push(
        context,
        _fadeRoute(TVAllGenresDetailsScreen(allGenres: _allGenres)),
      ),
    );

    final genreItems = _filteredGenres.asMap().entries.map((entry) {
      final i = entry.key;
      final g = entry.value;
      return _TVGenreGridItem(
        label: g.name,
        icon: _genreIcon(g.name),
        isAll: false,
        index: i,
        onTap: () => Navigator.push(
          context,
          _fadeRoute(TVGenreDetailsScreen(genre: g, allGenres: _allGenres)),
        ),
      );
    }).toList();

    final allItems = [allItem, ...genreItems];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: allItems.length,
      itemBuilder: (_, i) => allItems[i],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: _kTvAccent, strokeWidth: 2),
      );
    }

    final hasGenres = _filteredGenres.isNotEmpty;
    final hasShows = _searchedShows.isNotEmpty;

    if (!hasGenres && !hasShows) {
      return Center(
        child: Text(
          'No results for "$_searchQuery"',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasGenres) ...[
            _sectionTitle('Matching Genres'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _filteredGenres.length,
              itemBuilder: (_, i) {
                final g = _filteredGenres[i];
                return _TVGenreGridItem(
                  label: g.name,
                  icon: _genreIcon(g.name),
                  isAll: false,
                  index: i,
                  onTap: () => Navigator.push(
                    context,
                    _fadeRoute(
                      TVGenreDetailsScreen(genre: g, allGenres: _allGenres),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          if (hasShows) ...[
            _sectionTitle('TV Shows'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: _searchedShows.length,
              itemBuilder: (_, i) => _TVGridCard(show: _searchedShows[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  IconData _genreIcon(String name) {
    switch (name.toLowerCase()) {
      case 'action & adventure':
        return Icons.local_fire_department_rounded;
      case 'animation':
        return Icons.animation_rounded;
      case 'comedy':
        return Icons.sentiment_very_satisfied_rounded;
      case 'crime':
        return Icons.gavel_rounded;
      case 'documentary':
        return Icons.camera_alt_rounded;
      case 'drama':
        return Icons.theater_comedy_rounded;
      case 'family':
        return Icons.family_restroom_rounded;
      case 'kids':
        return Icons.child_care_rounded;
      case 'mystery':
        return Icons.search_rounded;
      case 'news':
        return Icons.newspaper_rounded;
      case 'reality':
        return Icons.live_tv_rounded;
      case 'sci-fi & fantasy':
        return Icons.rocket_launch_rounded;
      case 'soap':
        return Icons.favorite_rounded;
      case 'talk':
        return Icons.mic_rounded;
      case 'war & politics':
        return Icons.military_tech_rounded;
      case 'western':
        return Icons.landscape_rounded;
      default:
        return Icons.tv_rounded;
    }
  }
}

// TV Genre Grid Item

class _TVGenreGridItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isAll;
  final int index;
  final VoidCallback onTap;

  const _TVGenreGridItem({
    required this.label,
    required this.icon,
    required this.isAll,
    required this.index,
    required this.onTap,
  });

  Color _cardColor() {
    if (isAll) return _kTvAccent;
    final colors = [
      const Color(0xFF1E2A4A),
      const Color(0xFF1A2E1A),
      const Color(0xFF2E1A1A),
      const Color(0xFF1A1A2E),
      const Color(0xFF2A1E10),
      const Color(0xFF10202A),
      const Color(0xFF201A2E),
      const Color(0xFF2E2010),
    ];
    return colors[index % colors.length];
  }

  Color _accentColor() {
    if (isAll) return Colors.white;
    final colors = [
      const Color(0xFF4A80F0),
      const Color(0xFF4ACA6A),
      const Color(0xFFE55050),
      const Color(0xFF9A6AF0),
      const Color(0xFFE5A030),
      const Color(0xFF30C0E5),
      const Color(0xFFD060E0),
      const Color(0xFFE0A020),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAll
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: isAll
              ? [
                  BoxShadow(
                    color: _kTvAccent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _accentColor(), size: 28),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isAll
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
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
