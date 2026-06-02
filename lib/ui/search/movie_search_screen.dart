import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../movie/movie_details.dart';
import '../../model/movie_model.dart';

const String _kSearchApiKey = '2d688d383e42456bd08cf38e9d73ff22';

// Sort Options

class _SortOption {
  final String label;
  final String value;
  const _SortOption(this.label, this.value);
}

const List<_SortOption> _kSortOptions = [
  _SortOption('Popularity Descending', 'popularity.desc'),
  _SortOption('Popularity Ascending', 'popularity.asc'),
  _SortOption('Rating Descending', 'vote_average.desc'),
  _SortOption('Rating Ascending', 'vote_average.asc'),
  _SortOption('Release Date Descending', 'release_date.desc'),
  _SortOption('Release Date Ascending', 'release_date.asc'),
  _SortOption('Title (A-Z)', 'title.asc'),
  _SortOption('Title (Z-A)', 'title.desc'),
];

// Genre Model (same as genres_screen.dart)

class _Genre {
  final int id;
  final String name;
  const _Genre({required this.id, required this.name});
}

// Language Option

class _LangOption {
  final String code;
  final String name;
  const _LangOption(this.code, this.name);
}

const List<_LangOption> _kLanguages = [
  _LangOption('', 'None Selected'),
  _LangOption('en', 'English'),
  _LangOption('hi', 'Hindi'),
  _LangOption('ko', 'Korean'),
  _LangOption('ja', 'Japanese'),
  _LangOption('zh', 'Chinese'),
  _LangOption('fr', 'French'),
  _LangOption('es', 'Spanish'),
  _LangOption('de', 'German'),
  _LangOption('it', 'Italian'),
  _LangOption('pt', 'Portuguese'),
  _LangOption('ru', 'Russian'),
  _LangOption('ar', 'Arabic'),
  _LangOption('tr', 'Turkish'),
  _LangOption('th', 'Thai'),
  _LangOption('bn', 'Bengali'),
  _LangOption('sv', 'Swedish'),
  _LangOption('da', 'Danish'),
  _LangOption('nl', 'Dutch'),
  _LangOption('pl', 'Polish'),
];

// Filter State

class _FilterState {
  String sortBy;
  List<int> selectedGenreIds;
  String? releaseDateFrom;
  String? releaseDateTo;
  double voteAverageMin;
  double voteAverageMax;
  int voteCountMin;
  int runtimeMin;
  int runtimeMax;
  String language;

  _FilterState({
    this.sortBy = 'popularity.desc',
    List<int>? selectedGenreIds,
    this.releaseDateFrom,
    this.releaseDateTo,
    this.voteAverageMin = 0,
    this.voteAverageMax = 10,
    this.voteCountMin = 0,
    this.runtimeMin = 0,
    this.runtimeMax = 360,
    this.language = '',
  }) : selectedGenreIds = selectedGenreIds ?? [];

  _FilterState copyWith({
    String? sortBy,
    List<int>? selectedGenreIds,
    String? releaseDateFrom,
    String? releaseDateTo,
    double? voteAverageMin,
    double? voteAverageMax,
    int? voteCountMin,
    int? runtimeMin,
    int? runtimeMax,
    String? language,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) {
    return _FilterState(
      sortBy: sortBy ?? this.sortBy,
      selectedGenreIds: selectedGenreIds ?? List.from(this.selectedGenreIds),
      releaseDateFrom: clearFromDate
          ? null
          : (releaseDateFrom ?? this.releaseDateFrom),
      releaseDateTo: clearToDate ? null : (releaseDateTo ?? this.releaseDateTo),
      voteAverageMin: voteAverageMin ?? this.voteAverageMin,
      voteAverageMax: voteAverageMax ?? this.voteAverageMax,
      voteCountMin: voteCountMin ?? this.voteCountMin,
      runtimeMin: runtimeMin ?? this.runtimeMin,
      runtimeMax: runtimeMax ?? this.runtimeMax,
      language: language ?? this.language,
    );
  }

  bool get isDefault =>
      sortBy == 'popularity.desc' &&
      selectedGenreIds.isEmpty &&
      releaseDateFrom == null &&
      releaseDateTo == null &&
      voteAverageMin == 0 &&
      voteAverageMax == 10 &&
      voteCountMin == 0 &&
      runtimeMin == 0 &&
      runtimeMax == 360 &&
      language == '';

  String get sortLabel => _kSortOptions
      .firstWhere((o) => o.value == sortBy, orElse: () => _kSortOptions.first)
      .label;

  /// Build TMDB discover query params (excluding api_key, language, page)
  Map<String, String> toQueryParams() {
    final params = <String, String>{'sort_by': sortBy};
    if (selectedGenreIds.isNotEmpty) {
      // AND query: comma separated → only movies that have ALL selected genres
      params['with_genres'] = selectedGenreIds.join(',');
    }
    if (releaseDateFrom != null && releaseDateFrom!.isNotEmpty) {
      params['primary_release_date.gte'] = releaseDateFrom!;
    }
    if (releaseDateTo != null && releaseDateTo!.isNotEmpty) {
      params['primary_release_date.lte'] = releaseDateTo!;
    }
    if (voteAverageMin > 0) {
      params['vote_average.gte'] = voteAverageMin.toStringAsFixed(1);
    }
    if (voteAverageMax < 10) {
      params['vote_average.lte'] = voteAverageMax.toStringAsFixed(1);
    }
    if (voteCountMin > 0) {
      params['vote_count.gte'] = voteCountMin.toString();
    }
    if (runtimeMin > 0) {
      params['with_runtime.gte'] = runtimeMin.toString();
    }
    if (runtimeMax < 360) {
      params['with_runtime.lte'] = runtimeMax.toString();
    }
    if (language.isNotEmpty) {
      params['with_original_language'] = language;
    }
    return params;
  }
}

// SearchScreen

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<MovieModel> _movies = [];
  List<MovieModel> _searchResults = [];
  List<_Genre> _genres = [];

  bool _isLoading = true;
  bool _isSearching = false;
  bool _hasSearchText = false;
  int _currentPage = 1;
  bool _isFetchingMore = false;
  bool _hasMorePages = true;

  _FilterState _filterState = _FilterState();
  // Temporary state while drawer is open
  _FilterState _draftFilter = _FilterState();

  @override
  void initState() {
    super.initState();
    _fetchGenres();
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

  // Scroll

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 400 &&
        !_isFetchingMore &&
        _hasMorePages &&
        !_hasSearchText) {
      _fetchMoreMovies();
    }
  }

  // Genre Fetch

  Future<void> _fetchGenres() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/genre/movie/list?api_key=$_kSearchApiKey&language=en-US',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List genres = data['genres'];
        if (mounted) {
          setState(() {
            _genres = genres
                .map((g) => _Genre(id: g['id'], name: g['name']))
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  // Movie Fetch

  Future<void> _fetchMovies({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _movies = [];
        _currentPage = 1;
        _hasMorePages = true;
      });
    }

    try {
      final params = {
        'api_key': _kSearchApiKey,
        'language': 'en-US',
        'page': '1',
        ..._filterState.toQueryParams(),
      };
      final uri = Uri.https('api.themoviedb.org', '/3/discover/movie', params);
      final res = await http.get(uri);
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
      final params = {
        'api_key': _kSearchApiKey,
        'language': 'en-US',
        'page': nextPage.toString(),
        ..._filterState.toQueryParams(),
      };
      final uri = Uri.https('api.themoviedb.org', '/3/discover/movie', params);
      final res = await http.get(uri);
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
          'https://api.themoviedb.org/3/search/movie?api_key=$_kSearchApiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1',
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

  // Drawer

  void _openFilterDrawer() {
    _draftFilter = _filterState.copyWith();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: slide,
          child: Align(
            alignment: Alignment.centerRight,
            child: _FilterDrawer(
              initialFilter: _draftFilter,
              genres: _genres,
              onApply: (filter) {
                setState(() => _filterState = filter);
                Navigator.pop(ctx);
                _fetchMovies(reset: true);
              },
              onReset: () {
                setState(() => _filterState = _FilterState());
                Navigator.pop(ctx);
                _fetchMovies(reset: true);
              },
            ),
          ),
        );
      },
    );
  }

  // Active Filter Count

  int get _activeFilterCount {
    int count = 0;
    if (_filterState.sortBy != 'popularity.desc') count++;
    if (_filterState.selectedGenreIds.isNotEmpty) count++;
    if (_filterState.releaseDateFrom != null ||
        _filterState.releaseDateTo != null)
      count++;
    if (_filterState.voteAverageMin > 0 || _filterState.voteAverageMax < 10)
      count++;
    if (_filterState.voteCountMin > 0) count++;
    if (_filterState.runtimeMin > 0 || _filterState.runtimeMax < 360) count++;
    if (_filterState.language.isNotEmpty) count++;
    return count;
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
            _buildTopBar(),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // Top bar: back + search bar + filter chip

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Search bar
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A28),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? const Color(0xFFE50914).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      autofocus: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search movies...',
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
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Filter chip button
          GestureDetector(
            onTap: _openFilterDrawer,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _activeFilterCount > 0
                    ? const Color(0xFFE50914).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _activeFilterCount > 0
                      ? const Color(0xFFE50914).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: _activeFilterCount > 0
                        ? const Color(0xFFE50914)
                        : Colors.white.withValues(alpha: 0.6),
                    size: 18,
                  ),
                  if (_activeFilterCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE50914),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Body

  Widget _buildBody() {
    if (_hasSearchText) return _buildSearchResults();
    return _buildDiscoverGrid();
  }

  Widget _buildDiscoverGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE50914),
          strokeWidth: 2,
        ),
      );
    }

    if (_movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              color: Colors.white.withValues(alpha: 0.2),
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              'No movies found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() => _filterState = _FilterState());
                _fetchMovies(reset: true);
              },
              child: Text(
                'Reset filters',
                style: TextStyle(
                  color: const Color(0xFFE50914).withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            '${_movies.length} movies found',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 10,
              childAspectRatio: 0.62,
            ),
            itemCount: _movies.length + (_isFetchingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _movies.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: Color(0xFFE50914),
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              return _MovieGridCard(movie: _movies[index]);
            },
          ),
        ), // Expanded
      ], // Column
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE50914),
          strokeWidth: 2,
        ),
      );
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'No results for "${_searchController.text}"',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) =>
          _MovieGridCard(movie: _searchResults[index]),
    );
  }
}

// Filter Drawer

class _FilterDrawer extends StatefulWidget {
  final _FilterState initialFilter;
  final List<_Genre> genres;
  final ValueChanged<_FilterState> onApply;
  final VoidCallback onReset;

  const _FilterDrawer({
    required this.initialFilter,
    required this.genres,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<_FilterDrawer> {
  late _FilterState _draft;
  bool _sortExpanded = true;
  bool _filtersExpanded = true;

  // Date controllers
  final TextEditingController _fromDateCtrl = TextEditingController();
  final TextEditingController _toDateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilter.copyWith();
    _fromDateCtrl.text = _draft.releaseDateFrom ?? '';
    _toDateCtrl.text = _draft.releaseDateTo ?? '';
  }

  @override
  void dispose() {
    _fromDateCtrl.dispose();
    _toDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_draft.releaseDateFrom != null
              ? DateTime.tryParse(_draft.releaseDateFrom!) ?? now
              : now)
        : (_draft.releaseDateTo != null
              ? DateTime.tryParse(_draft.releaseDateTo!) ?? now
              : now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE50914),
              surface: Color(0xFF1A1A28),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0A0A0F),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        if (isFrom) {
          _draft = _draft.copyWith(releaseDateFrom: formatted);
          _fromDateCtrl.text = formatted;
        } else {
          _draft = _draft.copyWith(releaseDateTo: formatted);
          _toDateCtrl.text = formatted;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              bottomLeft: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              _buildDrawerHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSortSection(),
                      const SizedBox(height: 8),
                      _buildFiltersSection(),
                    ],
                  ),
                ),
              ),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Sort & Filter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close,
                color: Colors.white.withValues(alpha: 0.6),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sort Section

  Widget _buildSortSection() {
    return _buildExpandableSection(
      title: 'Sort',
      expanded: _sortExpanded,
      onToggle: () => setState(() => _sortExpanded = !_sortExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Sort Results By'),
          const SizedBox(height: 10),
          _buildSortDropdown(),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _draft.sortBy,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A28),
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          selectedItemBuilder: (_) => _kSortOptions.map((o) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                o.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          items: _kSortOptions.map((o) {
            final isSelected = o.value == _draft.sortBy;
            return DropdownMenuItem(
              value: o.value,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  o.label,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFE50914) : Colors.white,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _draft = _draft.copyWith(sortBy: v));
          },
        ),
      ),
    );
  }

  // Filters Section

  Widget _buildFiltersSection() {
    return _buildExpandableSection(
      title: 'Filters',
      expanded: _filtersExpanded,
      onToggle: () => setState(() => _filtersExpanded = !_filtersExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Release Dates
          _sectionLabel('Release Dates'),
          const SizedBox(height: 10),
          _buildDateRow('From', _fromDateCtrl, true),
          const SizedBox(height: 8),
          _buildDateRow('To', _toDateCtrl, false),
          const SizedBox(height: 20),

          // Genres
          _sectionLabel('Genres'),
          const SizedBox(height: 10),
          _buildGenreChips(),
          const SizedBox(height: 20),

          // Language
          _sectionLabel('Language'),
          const SizedBox(height: 10),
          _buildLanguageDropdown(),
          const SizedBox(height: 20),

          // User Score
          _sectionLabel(
            'User Score  ${_draft.voteAverageMin.toStringAsFixed(0)} – ${_draft.voteAverageMax.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 6),
          _buildRangeSlider(
            min: 0,
            max: 10,
            start: _draft.voteAverageMin,
            end: _draft.voteAverageMax,
            divisions: 10,
            onChanged: (s, e) => setState(() {
              _draft = _draft.copyWith(voteAverageMin: s, voteAverageMax: e);
            }),
          ),
          const SizedBox(height: 14),

          // Minimum Votes
          _sectionLabel('Minimum User Votes  ${_draft.voteCountMin}'),
          const SizedBox(height: 6),
          _buildSingleSlider(
            value: _draft.voteCountMin.toDouble(),
            min: 0,
            max: 500,
            divisions: 50,
            onChanged: (v) => setState(
              () => _draft = _draft.copyWith(voteCountMin: v.toInt()),
            ),
          ),
          const SizedBox(height: 14),

          // Runtime
          _sectionLabel(
            'Runtime (min)  ${_draft.runtimeMin} – ${_draft.runtimeMax}',
          ),
          const SizedBox(height: 6),
          _buildRangeSlider(
            min: 0,
            max: 360,
            start: _draft.runtimeMin.toDouble(),
            end: _draft.runtimeMax.toDouble(),
            divisions: 36,
            onChanged: (s, e) => setState(() {
              _draft = _draft.copyWith(
                runtimeMin: s.toInt(),
                runtimeMax: e.toInt(),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, TextEditingController ctrl, bool isFrom) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDate(isFrom),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ctrl.text.isEmpty ? '' : ctrl.text,
                      style: TextStyle(
                        color: ctrl.text.isEmpty
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white.withValues(alpha: 0.35),
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenreChips() {
    if (widget.genres.isEmpty) {
      return Text(
        'Loading genres...',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 13,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.genres.map((g) {
        final selected = _draft.selectedGenreIds.contains(g.id);
        return GestureDetector(
          onTap: () {
            setState(() {
              final ids = List<int>.from(_draft.selectedGenreIds);
              if (selected) {
                ids.remove(g.id);
              } else {
                ids.add(g.id);
              }
              _draft = _draft.copyWith(selectedGenreIds: ids);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFE50914).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? const Color(0xFFE50914).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              g.name,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFE50914)
                    : Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _draft.language,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A28),
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          selectedItemBuilder: (_) => _kLanguages.map((l) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l.name,
                style: TextStyle(
                  color: l.code.isEmpty
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          items: _kLanguages.map((l) {
            final isSelected = l.code == _draft.language;
            return DropdownMenuItem(
              value: l.code,
              child: Text(
                l.name,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFE50914)
                      : l.code.isEmpty
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null)
              setState(() => _draft = _draft.copyWith(language: v));
          },
        ),
      ),
    );
  }

  Widget _buildRangeSlider({
    required double min,
    required double max,
    required double start,
    required double end,
    required int divisions,
    required void Function(double, double) onChanged,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(0xFFE50914),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
        thumbColor: Colors.white,
        overlayColor: const Color(0xFFE50914).withValues(alpha: 0.15),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 8,
        ),
      ),
      child: RangeSlider(
        min: min,
        max: max,
        divisions: divisions,
        values: RangeValues(start, end),
        onChanged: (v) => onChanged(v.start, v.end),
      ),
    );
  }

  Widget _buildSingleSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(0xFFE50914),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
        thumbColor: Colors.white,
        overlayColor: const Color(0xFFE50914).withValues(alpha: 0.15),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      child: Slider(
        min: min,
        max: max,
        divisions: divisions,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  // Bottom Buttons

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: widget.onReset,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => widget.onApply(_draft),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE50914).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers

  Widget _buildExpandableSection({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onToggle,
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 22,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Divider(color: Colors.white.withValues(alpha: 0.08), thickness: 1),
        if (expanded) ...[const SizedBox(height: 14), child],
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

// Movie Grid Card (same look as other screens)

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
              borderRadius: BorderRadius.circular(12),
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
                      height: 55,
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
                      bottom: 7,
                      left: 7,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 11,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            movie.voteAverage!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
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
          const SizedBox(height: 6),
          Text(
            movie.title ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          if (movie.releaseDate != null && movie.releaseDate!.length >= 4)
            Text(
              movie.releaseDate!.substring(0, 4),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
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
        child: Icon(Icons.movie_outlined, color: Color(0xFF3A3A50), size: 26),
      ),
    );
  }
}
