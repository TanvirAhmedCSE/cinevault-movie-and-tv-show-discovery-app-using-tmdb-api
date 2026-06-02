import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '/model/tv_model.dart';
import '/ui/tv/tv_details.dart';
import '../../../constants/constants.dart';

class TvListItem extends StatelessWidget {
  final TVModel tvModel;
  const TvListItem({super.key, required this.tvModel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => TVDetails(tvModel: tvModel),
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
                      imageUrl: kmoviedbImageURL + (tvModel.posterPath ?? ''),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF0D1F2D),
                        child: const Center(
                          child: Icon(
                            Icons.tv_rounded,
                            color: Color(0xFF1E3A4A),
                            size: 28,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF0D1F2D),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF1E3A4A),
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
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Rating badge bottom-left
                    if (tvModel.voteAverage != null)
                      Positioned(
                        bottom: 6,
                        left: 8,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFF00D4C8),
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              tvModel.voteAverage!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // TV badge top-right
                    // Positioned(
                    //   top: 8,
                    //   right: 8,
                    //   child: Container(
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: 6, vertical: 3),
                    //     decoration: BoxDecoration(
                    //       color: const Color(0xFF00D4C8).withValues(alpha: 0.9),
                    //       borderRadius: BorderRadius.circular(4),
                    //     ),
                    //     child: const Text(
                    //       'SERIES',
                    //       style: TextStyle(
                    //         color: Colors.black,
                    //         fontSize: 8,
                    //         fontWeight: FontWeight.w800,
                    //         letterSpacing: 0.8,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tvModel.name ?? tvModel.originalName ?? '',
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
            if (tvModel.firstAirDate != null &&
                tvModel.firstAirDate!.length >= 4)
              Text(
                tvModel.firstAirDate!.substring(0, 4),
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
