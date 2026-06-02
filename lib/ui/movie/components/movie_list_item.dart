import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '/model/movie_model.dart';
import '/ui/movie/movie_details.dart';
import '../../../constants/constants.dart';

class MovieListItem extends StatelessWidget {
  final MovieModel movieModel;

  const MovieListItem({super.key, required this.movieModel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => MovieDetails(movieModel: movieModel),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16),
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster card
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          kmoviedbImageURL + (movieModel.posterPath ?? ''),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF1A1A28),
                        child: const Center(
                          child: Icon(
                            Icons.movie_outlined,
                            color: Color(0xFF3A3A50),
                            size: 28,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF1A1A28),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF3A3A50),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Rating badge
                    if (movieModel.voteAverage != null)
                      Positioned(
                        bottom: 6,
                        left: 8,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB800),
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              movieModel.voteAverage!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
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
              movieModel.title ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 2),
            if (movieModel.releaseDate != null &&
                movieModel.releaseDate!.length >= 4)
              Text(
                movieModel.releaseDate!.substring(0, 4),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
