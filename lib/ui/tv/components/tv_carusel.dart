import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter/material.dart';
import '/constants/constants.dart';
import '/model/tv_model.dart';
import '/ui/tv/tv_details.dart';

class TVCarusel extends StatefulWidget {
  final List<TVModel> tvModelList;
  const TVCarusel({super.key, required this.tvModelList});

  @override
  State<TVCarusel> createState() => _TVCaruselState();
}

class _TVCaruselState extends State<TVCarusel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final shows = widget.tvModelList;
    if (shows.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 460,
      child: Stack(
        children: [
          // Backdrop image with animated switcher
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: CachedNetworkImage(
              key: ValueKey(_currentIndex),
              imageUrl:
                  kmoviedbImageURL +
                  (shows[_currentIndex].backdropPath ??
                      shows[_currentIndex].posterPath ??
                      ''),
              width: double.infinity,
              height: 460,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: const Color(0xFF0A1628)),
              errorWidget: (_, __, ___) =>
                  Container(color: const Color(0xFF0A1628)),
            ),
          ),

          // Deep teal-to-dark gradient overlay (TV feel — different from movie's red)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A0F).withValues(alpha: 0.25),
                    Colors.transparent,
                    const Color(0xFF050D1A).withValues(alpha: 0.65),
                    const Color(0xFF050D1A),
                  ],
                  stops: const [0.0, 0.25, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Left side vignette
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF050D1A).withValues(alpha: 0.6),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Carousel — invisible swipe layer
          FlutterCarousel.builder(
            itemCount: shows.length,
            itemBuilder: (context, itemIndex, pageViewIndex) {
              return GestureDetector(
                onTap: () =>
                    Navigator.push(context, _buildRoute(shows[itemIndex])),
                child: Container(color: Colors.transparent),
              );
            },
            options: CarouselOptions(
              height: 460,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 900),
              autoPlayCurve: Curves.easeInOutCubic,
              enableInfiniteScroll: true,
              showIndicator: false,
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
          ),

          // Bottom info panel
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AIRING TODAY badge — teal instead of red
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4C8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AIRING TODAY',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  shows[_currentIndex].name ??
                      shows[_currentIndex].originalName ??
                      '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF00D4C8),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shows[_currentIndex].voteAverage?.toStringAsFixed(1) ??
                          '',
                      style: const TextStyle(
                        color: Color(0xFF00D4C8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (shows[_currentIndex].firstAirDate != null &&
                        shows[_currentIndex].firstAirDate!.length >= 4)
                      Text(
                        shows[_currentIndex].firstAirDate!.substring(0, 4),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    if (shows[_currentIndex].originCountry != null &&
                        shows[_currentIndex].originCountry!.isNotEmpty) ...[
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
                          shows[_currentIndex].originCountry!.first,
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
                    // Watch Now — teal button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          _buildRoute(shows[_currentIndex]),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D4C8), Color(0xFF0099A8)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Watch Now',
                                style: TextStyle(
                                  color: Colors.black,
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
                    // Info button
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        _buildRoute(shows[_currentIndex]),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
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
                const SizedBox(height: 16),
                // Dot indicators — teal accent
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      shows.length > 20 ? 20 : shows.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 4),
                        width: _currentIndex == i ? 20 : 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _currentIndex == i
                              ? const Color(0xFF00D4C8)
                              : Colors.white.withValues(alpha: 0.25),
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

  PageRouteBuilder _buildRoute(TVModel show) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => TVDetails(tvModel: show),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
