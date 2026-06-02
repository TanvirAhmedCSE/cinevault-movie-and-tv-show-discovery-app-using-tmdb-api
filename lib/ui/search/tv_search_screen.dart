import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../tv/tv_details.dart';
import '../../model/tv_model.dart';

const String _kTvSearchApiKey = '2d688d383e42456bd08cf38e9d73ff22';
const Color _kTvSearchAccent = Color(0xFF00D4C8);

// Sort Options

class _SortOption {
  final String label;
  final String value;
  const _SortOption(this.label, this.value);
}

const List<_SortOption> _kTvSortOptions = [
  _SortOption('Popularity Descending', 'popularity.desc'),
  _SortOption('Popularity Ascending', 'popularity.asc'),
  _SortOption('Rating Descending', 'vote_average.desc'),
  _SortOption('Rating Ascending', 'vote_average.asc'),
  _SortOption('First Air Date Descending', 'first_air_date.desc'),
  _SortOption('First Air Date Ascending', 'first_air_date.asc'),
  _SortOption('Name (A-Z)', 'name.asc'),
  _SortOption('Name (Z-A)', 'name.desc'),
];

// Genre Model

class _TVGenre {
  final int id;
  final String name;
  const _TVGenre({required this.id, required this.name});
}

// Country Option

class _CountryOption {
  final String code;
  final String name;
  const _CountryOption(this.code, this.name);
}

const List<_CountryOption> _kCountries = [
  _CountryOption('', 'None Selected'),
  _CountryOption('US', 'United States'),
  _CountryOption('GB', 'United Kingdom'),
  _CountryOption('KR', 'South Korea'),
  _CountryOption('JP', 'Japan'),
  _CountryOption('IN', 'India'),
  _CountryOption('CN', 'China'),
  _CountryOption('FR', 'France'),
  _CountryOption('DE', 'Germany'),
  _CountryOption('ES', 'Spain'),
  _CountryOption('IT', 'Italy'),
  _CountryOption('BR', 'Brazil'),
  _CountryOption('MX', 'Mexico'),
  _CountryOption('CA', 'Canada'),
  _CountryOption('AU', 'Australia'),
  _CountryOption('TR', 'Turkey'),
  _CountryOption('TH', 'Thailand'),
  _CountryOption('SE', 'Sweden'),
  _CountryOption('DK', 'Denmark'),
  _CountryOption('NO', 'Norway'),
  _CountryOption('NL', 'Netherlands'),
  _CountryOption('BD', 'Bangladesh'),
];

// Filter State

class _TVFilterState {
  String sortBy;
  List<int> selectedGenreIds;
  String? firstAirDateFrom;
  String? firstAirDateTo;
  double voteAverageMin;
  double voteAverageMax;
  int voteCountMin;
  String country;

  _TVFilterState({
    this.sortBy = 'popularity.desc',
    List<int>? selectedGenreIds,
    this.firstAirDateFrom,
    this.firstAirDateTo,
    this.voteAverageMin = 0,
    this.voteAverageMax = 10,
    this.voteCountMin = 0,
    this.country = '',
  }) : selectedGenreIds = selectedGenreIds ?? [];

  _TVFilterState copyWith({
    String? sortBy,
    List<int>? selectedGenreIds,
    String? firstAirDateFrom,
    String? firstAirDateTo,
    double? voteAverageMin,
    double? voteAverageMax,
    int? voteCountMin,
    String? country,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) {
    return _TVFilterState(
      sortBy: sortBy ?? this.sortBy,
      selectedGenreIds: selectedGenreIds ?? List.from(this.selectedGenreIds),
      firstAirDateFrom: clearFromDate
          ? null
          : (firstAirDateFrom ?? this.firstAirDateFrom),
      firstAirDateTo: clearToDate
          ? null
          : (firstAirDateTo ?? this.firstAirDateTo),
      voteAverageMin: voteAverageMin ?? this.voteAverageMin,
      voteAverageMax: voteAverageMax ?? this.voteAverageMax,
      voteCountMin: voteCountMin ?? this.voteCountMin,
      country: country ?? this.country,
    );
  }

  bool get isDefault =>
      sortBy == 'popularity.desc' &&
      selectedGenreIds.isEmpty &&
      firstAirDateFrom == null &&
      firstAirDateTo == null &&
      voteAverageMin == 0 &&
      voteAverageMax == 10 &&
      voteCountMin == 0 &&
      country == '';

  Map<String, String> toQueryParams() {
    final params = <String, String>{'sort_by': sortBy};
    if (selectedGenreIds.isNotEmpty) {
      params['with_genres'] = selectedGenreIds.join(',');
    }
    if (firstAirDateFrom != null && firstAirDateFrom!.isNotEmpty) {
      params['first_air_date.gte'] = firstAirDateFrom!;
    }
    if (firstAirDateTo != null && firstAirDateTo!.isNotEmpty) {
      params['first_air_date.lte'] = firstAirDateTo!;
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
    if (country.isNotEmpty) {
      params['with_origin_country'] = country;
    }
    return params;
  }
}

// TVSearchScreen

class TVSearchScreen extends StatefulWidget {
  const TVSearchScreen({super.key});

  @override
  State<TVSearchScreen> createState() => _TVSearchScreenState();
}

class _TVSearchScreenState extends State<TVSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<TVModel> _shows = [];
  List<TVModel> _searchResults = [];
  List<_TVGenre> _genres = [];

  bool _isLoading = true;
  bool _isSearching = false;
  bool _hasSearchText = false;
  int _currentPage = 1;
  bool _isFetchingMore = false;
  bool _hasMorePages = true;

  _TVFilterState _filterState = _TVFilterState();
  _TVFilterState _draftFilter = _TVFilterState();

  @override
  void initState() {
    super.initState();
    _fetchGenres();
    _fetchShows();
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
            _scrollController.position.maxScrollExtent - 400 &&
        !_isFetchingMore &&
        _hasMorePages &&
        !_hasSearchText) {
      _fetchMoreShows();
    }
  }

  Future<void> _fetchGenres() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/genre/tv/list?api_key=$_kTvSearchApiKey&language=en-US',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List genres = data['genres'];
        if (mounted) {
          setState(() {
            _genres = genres
                .map((g) => _TVGenre(id: g['id'], name: g['name']))
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchShows({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _shows = [];
        _currentPage = 1;
        _hasMorePages = true;
      });
    }

    try {
      final params = {
        'api_key': _kTvSearchApiKey,
        'language': 'en-US',
        'page': '1',
        ..._filterState.toQueryParams(),
      };
      final uri = Uri.https('api.themoviedb.org', '/3/discover/tv', params);
      final res = await http.get(uri);
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
      final params = {
        'api_key': _kTvSearchApiKey,
        'language': 'en-US',
        'page': nextPage.toString(),
        ..._filterState.toQueryParams(),
      };
      final uri = Uri.https('api.themoviedb.org', '/3/discover/tv', params);
      final res = await http.get(uri);
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
          'https://api.themoviedb.org/3/search/tv?api_key=$_kTvSearchApiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1',
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
            child: _TVFilterDrawer(
              initialFilter: _draftFilter,
              genres: _genres,
              onApply: (filter) {
                setState(() => _filterState = filter);
                Navigator.pop(ctx);
                _fetchShows(reset: true);
              },
              onReset: () {
                setState(() => _filterState = _TVFilterState());
                Navigator.pop(ctx);
                _fetchShows(reset: true);
              },
            ),
          ),
        );
      },
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_filterState.sortBy != 'popularity.desc') count++;
    if (_filterState.selectedGenreIds.isNotEmpty) count++;
    if (_filterState.firstAirDateFrom != null ||
        _filterState.firstAirDateTo != null)
      count++;
    if (_filterState.voteAverageMin > 0 || _filterState.voteAverageMax < 10)
      count++;
    if (_filterState.voteCountMin > 0) count++;
    if (_filterState.country.isNotEmpty) count++;
    return count;
  }

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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
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
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A28),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? _kTvSearchAccent.withValues(alpha: 0.5)
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
                        hintText: 'Search TV shows...',
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
          GestureDetector(
            onTap: _openFilterDrawer,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _activeFilterCount > 0
                    ? _kTvSearchAccent.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _activeFilterCount > 0
                      ? _kTvSearchAccent.withValues(alpha: 0.5)
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
                        ? _kTvSearchAccent
                        : Colors.white.withValues(alpha: 0.6),
                    size: 18,
                  ),
                  if (_activeFilterCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: _kTvSearchAccent,
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

  Widget _buildBody() {
    if (_hasSearchText) return _buildSearchResults();
    return _buildDiscoverGrid();
  }

  Widget _buildDiscoverGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _kTvSearchAccent,
          strokeWidth: 2,
        ),
      );
    }

    if (_shows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tv_off_outlined,
              color: Colors.white.withValues(alpha: 0.2),
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              'No TV shows found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() => _filterState = _TVFilterState());
                _fetchShows(reset: true);
              },
              child: Text(
                'Reset filters',
                style: TextStyle(
                  color: _kTvSearchAccent.withValues(alpha: 0.8),
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
            '${_shows.length} TV shows found',
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
            itemCount: _shows.length + (_isFetchingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _shows.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: _kTvSearchAccent,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              return _TVGridCard(show: _shows[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: _kTvSearchAccent,
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
      itemBuilder: (context, index) => _TVGridCard(show: _searchResults[index]),
    );
  }
}

// TV Filter Drawer

class _TVFilterDrawer extends StatefulWidget {
  final _TVFilterState initialFilter;
  final List<_TVGenre> genres;
  final ValueChanged<_TVFilterState> onApply;
  final VoidCallback onReset;

  const _TVFilterDrawer({
    required this.initialFilter,
    required this.genres,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_TVFilterDrawer> createState() => _TVFilterDrawerState();
}

class _TVFilterDrawerState extends State<_TVFilterDrawer> {
  late _TVFilterState _draft;
  bool _sortExpanded = true;
  bool _filtersExpanded = true;

  final TextEditingController _fromDateCtrl = TextEditingController();
  final TextEditingController _toDateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilter.copyWith();
    _fromDateCtrl.text = _draft.firstAirDateFrom ?? '';
    _toDateCtrl.text = _draft.firstAirDateTo ?? '';
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
        ? (_draft.firstAirDateFrom != null
              ? DateTime.tryParse(_draft.firstAirDateFrom!) ?? now
              : now)
        : (_draft.firstAirDateTo != null
              ? DateTime.tryParse(_draft.firstAirDateTo!) ?? now
              : now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _kTvSearchAccent,
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
          _draft = _draft.copyWith(firstAirDateFrom: formatted);
          _fromDateCtrl.text = formatted;
        } else {
          _draft = _draft.copyWith(firstAirDateTo: formatted);
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
          selectedItemBuilder: (_) => _kTvSortOptions.map((o) {
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
          items: _kTvSortOptions.map((o) {
            final isSelected = o.value == _draft.sortBy;
            return DropdownMenuItem(
              value: o.value,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  o.label,
                  style: TextStyle(
                    color: isSelected ? _kTvSearchAccent : Colors.white,
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

  Widget _buildFiltersSection() {
    return _buildExpandableSection(
      title: 'Filters',
      expanded: _filtersExpanded,
      onToggle: () => setState(() => _filtersExpanded = !_filtersExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Air Dates
          _sectionLabel('First Air Date'),
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

          // Country
          _sectionLabel('Country of Origin'),
          const SizedBox(height: 10),
          _buildCountryDropdown(),
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
                  ? _kTvSearchAccent.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? _kTvSearchAccent.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              g.name,
              style: TextStyle(
                color: selected
                    ? _kTvSearchAccent
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

  Widget _buildCountryDropdown() {
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
          value: _draft.country,
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
          selectedItemBuilder: (_) => _kCountries.map((c) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                c.name,
                style: TextStyle(
                  color: c.code.isEmpty
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          items: _kCountries.map((c) {
            final isSelected = c.code == _draft.country;
            return DropdownMenuItem(
              value: c.code,
              child: Text(
                c.name,
                style: TextStyle(
                  color: isSelected
                      ? _kTvSearchAccent
                      : c.code.isEmpty
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _draft = _draft.copyWith(country: v));
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
        activeTrackColor: _kTvSearchAccent,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
        thumbColor: Colors.white,
        overlayColor: _kTvSearchAccent.withValues(alpha: 0.15),
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
        activeTrackColor: _kTvSearchAccent,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
        thumbColor: Colors.white,
        overlayColor: _kTvSearchAccent.withValues(alpha: 0.15),
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
                  color: _kTvSearchAccent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _kTvSearchAccent.withValues(alpha: 0.35),
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
              borderRadius: BorderRadius.circular(12),
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
                  if (show.voteAverage != null)
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
                            show.voteAverage!.toStringAsFixed(1),
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
            show.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          if (show.firstAirDate != null && show.firstAirDate!.length >= 4)
            Text(
              show.firstAirDate!.substring(0, 4),
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
        child: Icon(Icons.tv_outlined, color: Color(0xFF3A3A50), size: 26),
      ),
    );
  }
}
