import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../model/cast_model.dart';
import '../model/movie_model.dart';
import '../service/api_service.dart';
import '../constants/constants.dart';
import 'movie/movie_details.dart';

class CastDetailScreen extends StatefulWidget {
  final CastModel castModel;
  final Color accentColor; // movie → 0xFFE50914, tv → 0xFF00D4C8

  const CastDetailScreen({
    super.key,
    required this.castModel,
    this.accentColor = const Color(0xFFE50914),
  });

  @override
  State<CastDetailScreen> createState() => _CastDetailScreenState();
}

class _CastDetailScreenState extends State<CastDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _detailsFuture;
  late Future<List<MovieModel>> _moviesFuture;
  bool _isBioExpanded = false;

  // Shorthand getter — avoids repeating widget.accentColor everywhere
  Color get _accent => widget.accentColor;

  @override
  void initState() {
    super.initState();
    final id = widget.castModel.id ?? 0;
    _detailsFuture = _apiService.getCastDetails(id);
    _moviesFuture = _apiService.getCastMovieCredits(id);
  }

  @override
  Widget build(BuildContext context) {
    final cast = widget.castModel;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: _accent == const Color(0xFFE50914)
                ? const Color(0xFF0A0A0F)
                : const Color(0xFF001F1E),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _buildHeroSection(cast),
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _detailsFuture,
              builder: (context, snapshot) {
                final details = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ).copyWith(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Name + department
                      Text(
                        cast.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      if (cast.knownForDepartment != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _accent.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            cast.knownForDepartment!.toUpperCase(),
                            style: TextStyle(
                              color: _accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Stats row
                      if (details != null) _buildStatsRow(details),

                      const SizedBox(height: 24),

                      // Biography
                      if (details != null &&
                          (details['biography'] as String? ?? '').isNotEmpty)
                        _buildBiography(details['biography'] as String),

                      const SizedBox(height: 28),

                      // Filmography
                      _buildFilmographySection(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Hero backdrop/poster section
  Widget _buildHeroSection(CastModel cast) {
    final imageUrl = cast.profilePath != null
        ? 'https://image.tmdb.org/t/p/w500' + cast.profilePath!
        : '';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred full-screen backdrop
        if (cast.profilePath != null)
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: const Color(0xFF141420)),
            errorWidget: (_, __, ___) =>
                Container(color: const Color(0xFF141420)),
          ),

        // Dark overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.5),
                const Color(0xFF0A0A0F).withValues(alpha: 0.85),
                const Color(0xFF0A0A0F),
              ],
              stops: const [0.0, 0.4, 0.75, 1.0],
            ),
          ),
        ),

        // Foreground: profile image + name area
        Positioned(
          bottom: 28,
          left: 20,
          right: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Profile circle with Hero animation
              Hero(
                tag: 'cast_${cast.id}',
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.6),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF1A1A28),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF3A3A50),
                          size: 40,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF1A1A28),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF3A3A50),
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _detailsFuture,
                  builder: (context, snapshot) {
                    final details = snapshot.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (details?['place_of_birth'] != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFF6B6B80),
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  details!['place_of_birth'] as String,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (details?['birthday'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.cake_rounded,
                                color: Color(0xFF6B6B80),
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(details!['birthday'] as String),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Stats row
  Widget _buildStatsRow(Map<String, dynamic> details) {
    final popularity = (details['popularity'] as num?)?.toDouble();
    final birthday = details['birthday'] as String?;
    final age = birthday != null ? _calculateAge(birthday) : null;
    final gender = details['gender'] as int?;
    final genderLabel = gender == 1
        ? 'Female'
        : gender == 2
        ? 'Male'
        : 'N/A';

    return Row(
      children: [
        if (popularity != null)
          Expanded(
            child: _StatCard(
              value: popularity.toStringAsFixed(1),
              label: 'Popularity',
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFFFFB800),
            ),
          ),
        if (popularity != null) const SizedBox(width: 10),
        if (age != null)
          Expanded(
            child: _StatCard(
              value: '$age',
              label: 'Age',
              icon: Icons.person_outline_rounded,
              iconColor: const Color(0xFF4ECDC4),
            ),
          ),
        if (age != null) const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: genderLabel,
            label: 'Gender',
            icon: Icons.people_outline_rounded,
            iconColor: const Color(0xFF9B8EF5),
          ),
        ),
      ],
    );
  }

  // Biography
  Widget _buildBiography(String bio) {
    final isLong = bio.length > 300;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article_outlined, color: _accent, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Biography',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          firstChild: Text(
            bio,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
              height: 1.65,
            ),
          ),
          secondChild: Text(
            bio,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
              height: 1.65,
            ),
          ),
          crossFadeState: _isBioExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 280),
        ),
        if (isLong)
          GestureDetector(
            onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _isBioExpanded ? 'Show less' : 'Read more',
                style: TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  // Filmography section
  Widget _buildFilmographySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.movie_filter_rounded, color: _accent, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Filmography',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<MovieModel>>(
          future: _moviesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final movies = snapshot.data!;
              if (movies.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'No movies found.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 16),
                  itemCount: movies.length,
                  itemBuilder: (context, index) =>
                      _FilmographyCard(movie: movies[index]),
                ),
              );
            }
            if (snapshot.hasError) {
              return Text(
                'Failed to load filmography.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(
                  color: _accent,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Helpers
  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length < 3) return date;
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = int.tryParse(parts[1]) ?? 0;
      return '${parts[2]} ${months[month]} ${parts[0]}';
    } catch (_) {
      return date;
    }
  }

  int _calculateAge(String birthday) {
    try {
      final born = DateTime.parse(birthday);
      final now = DateTime.now();
      int age = now.year - born.year;
      if (now.month < born.month ||
          (now.month == born.month && now.day < born.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }
}

// Stat card widget
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// Filmography card
class _FilmographyCard extends StatelessWidget {
  final MovieModel movie;

  const _FilmographyCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => MovieDetails(movieModel: movie),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 0, right: 14),
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: movie.posterPath != null
                          ? kmoviedbImageURL + movie.posterPath!
                          : '',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF1A1A28),
                        child: const Center(
                          child: Icon(
                            Icons.movie_outlined,
                            color: Color(0xFF3A3A50),
                            size: 26,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF1A1A28),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF3A3A50),
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    // Bottom gradient + rating
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 48,
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
                        bottom: 6,
                        left: 7,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB800),
                              size: 11,
                            ),
                            const SizedBox(width: 3),
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
            const SizedBox(height: 7),
            Text(
              movie.title ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
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
      ),
    );
  }
}
