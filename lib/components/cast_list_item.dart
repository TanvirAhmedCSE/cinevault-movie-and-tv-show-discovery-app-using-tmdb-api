import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../model/cast_model.dart';
import '../constants/constants.dart';
import '../ui/cast_detail_screen.dart';

class CastListItem extends StatelessWidget {
  final CastModel castModel;
  final Color accentColor; // movie: 0xFFE50914, tv: 0xFF00D4C8

  const CastListItem({
    super.key,
    required this.castModel,
    this.accentColor = const Color(0xFFE50914),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => CastDetailScreen(
              castModel: castModel,
              accentColor: accentColor,
            ),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        width: 80,
        child: Column(
          children: [
            // Avatar
            Hero(
              tag: 'cast_${castModel.id}',
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: castModel.profilePath != null
                        ? kmoviedbImageURL + castModel.profilePath!
                        : '',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: const Color(0xFF1A1A28),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF3A3A50),
                        size: 30,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A28),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF3A3A50),
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              castModel.name ?? '',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              castModel.knownForDepartment ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
