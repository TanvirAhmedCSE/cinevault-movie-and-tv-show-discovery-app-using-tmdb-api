import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import '/model/movie_model.dart';
import '../../../constants/constants.dart';
import '../movie_details.dart';

class MovieCarousel extends StatefulWidget {
  final List<MovieModel> movieModelList;

  const MovieCarousel({super.key, required this.movieModelList});

  @override
  State<MovieCarousel> createState() => _MovieCarouselState();
}

class _MovieCarouselState extends State<MovieCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final movies = widget.movieModelList;
    if (movies.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 480,
      child: Stack(
        children: [
          // Backdrop
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: CachedNetworkImage(
              key: ValueKey(_currentIndex),
              imageUrl:
                  kmoviedbImageURL +
                  (movies[_currentIndex].backdropPath ??
                      movies[_currentIndex].posterPath ??
                      ''),
              width: double.infinity,
              height: 480,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: const Color(0xFF141420)),
              errorWidget: (_, __, ___) =>
                  Container(color: const Color(0xFF141420)),
            ),
          ),

          // Gradient overlays
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A0F).withValues(alpha: 0.3),
                    Colors.transparent,
                    const Color(0xFF0A0A0F).withValues(alpha: 0.6),
                    const Color(0xFF0A0A0F),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Side gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF0A0A0F).withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Carousel (invisible, just for swipe)
          FlutterCarousel.builder(
            itemCount: movies.length,
            itemBuilder: (context, itemIndex, pageViewIndex) {
              return GestureDetector(
                onTap: () =>
                    Navigator.push(context, _buildPageRoute(movies[itemIndex])),
                child: Container(color: Colors.transparent),
              );
            },
            options: CarouselOptions(
              height: 480,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.easeInOutCubic,
              enableInfiniteScroll: true,
              showIndicator: false,
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
          ),

          // Bottom info overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NOW PLAYING badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NOW PLAYING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  movies[_currentIndex].title ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // with language version
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: const Color(0xFFFFB800),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      movies[_currentIndex].voteAverage?.toStringAsFixed(1) ??
                          '',
                      style: const TextStyle(
                        color: Color(0xFFFFB800),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (movies[_currentIndex].releaseDate != null)
                      Text(
                        movies[_currentIndex].releaseDate!.substring(0, 4),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    if (movies[_currentIndex].originalLanguage != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          movies[_currentIndex].originalLanguage!.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Watch Now button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          _buildPageRoute(movies[_currentIndex]),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE50914),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Watch Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // More Info button
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        _buildPageRoute(movies[_currentIndex]),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Info',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Dot indicators
                const SizedBox(height: 16),

                // to put in center of the phone screen width
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      movies.length > 20 ? 20 : movies.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 4),
                        width: _currentIndex == i ? 20 : 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _currentIndex == i
                              ? const Color(0xFFE50914)
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PageRouteBuilder _buildPageRoute(MovieModel movie) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => MovieDetails(movieModel: movie),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
