import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '/model/movie_model.dart';
import '/model/video_model.dart';
import '/components/cast_page.dart';
import '../../constants/constants.dart';
import '../../service/api_service.dart';
import '../../service/wishlist_service.dart';
import 'movies_category.dart';

class MovieDetails extends StatefulWidget {
  final MovieModel movieModel;

  const MovieDetails({super.key, required this.movieModel});

  @override
  State<MovieDetails> createState() => _MovieDetailsState();
}

class _MovieDetailsState extends State<MovieDetails> {
  final ApiService _apiService = ApiService();
  YoutubePlayerController? _youtubeController;
  bool _isPlayerVisible = false;
  bool _isExpanded = false;
  late bool _isWishlisted;

  @override
  void initState() {
    super.initState();
    _isWishlisted = WishlistService.isMovieWishlisted(
      widget.movieModel.id ?? 0,
    );
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  void _launchPlayer(String videoKey) {
    _youtubeController?.dispose();
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoKey,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
      ),
    );
    setState(() => _isPlayerVisible = true);
  }

  void _closePlayer() {
    _youtubeController?.pause();
    setState(() => _isPlayerVisible = false);
  }

  Future<void> _toggleWishlist() async {
    final movie = widget.movieModel;
    final title = movie.title ?? movie.originalTitle ?? 'this movie';
    final year = (movie.releaseDate != null && movie.releaseDate!.length >= 4)
        ? movie.releaseDate!.substring(0, 4)
        : '';
    final displayName = year.isNotEmpty ? '$title ($year)' : title;

    if (_isWishlisted) {
      // Ask for confirmation before removing
      final confirmed = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C26),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Remove from Wishlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0x73FFFFFF),
                      fontSize: 13.5,
                      height: 1.6,
                    ),
                    children: [
                      const TextSpan(text: 'Do you want to remove '),
                      TextSpan(
                        text: displayName,
                        style: const TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' from your wishlist?'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(
                  color: Color(0x14FFFFFF),
                  height: 0.5,
                  thickness: 0.5,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 0.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0x80FFFFFF),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 0.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Remove',
                            style: TextStyle(
                              //color: Color(0xFFE50914),
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (confirmed != true) return;
      await WishlistService.removeMovie(movie.id ?? 0);
      if (mounted) setState(() => _isWishlisted = false);
    } else {
      await WishlistService.addMovie(movie);
      if (mounted) setState(() => _isWishlisted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movieModel;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero App Bar
          SliverAppBar(
            expandedHeight: _isPlayerVisible ? 240 : 320,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0A0A0F),
            leading: GestureDetector(
              onTap: () {
                if (_isPlayerVisible) _closePlayer();
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
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
              background: _isPlayerVisible && _youtubeController != null
                  ? _buildYoutubePlayer()
                  : _buildHeroImage(movie),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ).copyWith(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          movie.title ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Meta row
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (movie.voteAverage != null)
                        _MetaChip(
                          icon: Icons.star_rounded,
                          label:
                              '${movie.voteAverage!.toStringAsFixed(1)} / 10',
                          iconColor: const Color(0xFFFFB800),
                        ),
                      if (movie.releaseDate != null &&
                          movie.releaseDate!.length >= 4)
                        _MetaChip(
                          icon: Icons.calendar_today_rounded,
                          label: movie.releaseDate!.substring(0, 4),
                          iconColor: Colors.white54,
                        ),
                      if (movie.originalLanguage != null)
                        _MetaChip(
                          icon: Icons.language_rounded,
                          label: movie.originalLanguage!.toUpperCase(),
                          iconColor: Colors.white54,
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action buttons row
                  FutureBuilder<List<VideoModel>>(
                    future: _apiService.getVideo(
                      movie.id ?? 0,
                      ProgramType.movie,
                    ),
                    builder: (context, snapshot) {
                      final hasVideo =
                          snapshot.hasData && snapshot.data!.isNotEmpty;
                      return Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _ActionButton(
                              icon: Icons.play_arrow_rounded,
                              label: _isPlayerVisible
                                  ? 'Playing...'
                                  : 'Play Trailer',
                              isPrimary: true,
                              isLoading:
                                  snapshot.connectionState ==
                                  ConnectionState.waiting,
                              onTap: hasVideo
                                  ? () {
                                      if (_isPlayerVisible) {
                                        _closePlayer();
                                      } else {
                                        _launchPlayer(snapshot.data![0].key!);
                                      }
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _WishlistButton(
                              isWishlisted: _isWishlisted,
                              onTap: _toggleWishlist,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Overview
                  const Text(
                    'Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedCrossFade(
                    firstChild: Text(
                      movie.overview ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 14,
                        height: 1.6,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondChild: Text(
                      movie.overview ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                  if ((movie.overview ?? '').length > 150)
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _isExpanded ? 'Show less' : 'Read more',
                          style: const TextStyle(
                            color: Color(0xFFE50914),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Cast section
                  _SectionTitle(title: 'Cast', icon: Icons.people_rounded),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 150,
                    child: CastPage(
                      id: movie.id ?? 0,
                      type: ProgramType.movie,
                      accentColor: const Color(0xFFE50914),
                    ),
                  ),

                  // Similar movies
                  _SectionTitle(
                    title: 'More Like This',
                    icon: Icons.grid_view_rounded,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 210,
                    child: MoviesCategory(
                      movieType: MovieType.similar,
                      movieID: movie.id ?? 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(MovieModel movie) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl:
              kmoviedbImageURL + (movie.backdropPath ?? movie.posterPath ?? ''),
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: const Color(0xFF141420)),
          errorWidget: (_, __, ___) => Container(
            color: const Color(0xFF141420),
            child: const Icon(
              Icons.movie_outlined,
              color: Color(0xFF3A3A50),
              size: 60,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFF0A0A0F).withValues(alpha: 0.8),
                const Color(0xFF0A0A0F),
              ],
              stops: const [0.4, 0.8, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYoutubePlayer() {
    return Container(
      color: Colors.black,
      child: Center(
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFFE50914),
          progressColors: const ProgressBarColors(
            playedColor: Color(0xFFE50914),
            handleColor: Color(0xFFE50914),
          ),
          onEnded: (_) => _closePlayer(),
        ),
      ),
    );
  }
}

// Wishlist Button
class _WishlistButton extends StatelessWidget {
  final bool isWishlisted;
  final VoidCallback onTap;

  const _WishlistButton({required this.isWishlisted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isWishlisted
              ? const Color(0xFF1A7A4A)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: isWishlisted
              ? Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                )
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isWishlisted
              ? [
                  const Text(
                    'Wishlisted!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ]
              : [
                  const Icon(
                    Icons.bookmark_add_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Wishlist',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

// Shared widgets
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null && !isLoading;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary
              ? (isDisabled
                    ? const Color(0xFFE50914).withValues(alpha: 0.3)
                    : const Color(0xFFE50914))
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE50914), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
