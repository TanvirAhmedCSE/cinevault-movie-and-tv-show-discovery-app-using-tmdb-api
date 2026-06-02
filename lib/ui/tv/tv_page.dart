import 'package:flutter/material.dart';
import '/model/tv_model.dart';
import '/service/api_service.dart';
import '/ui/tv/tv_category.dart';
import 'components/tv_carusel.dart';
import '../genres/tv_genres_screen.dart';
import '../search/tv_search_screen.dart';
import '../see_all/tv_see_all_screen.dart';

class TVPage extends StatefulWidget {
  const TVPage({super.key});

  @override
  State<TVPage> createState() => _TVPageState();
}

class _TVPageState extends State<TVPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;

  // Nullable instead of late — safe before initState completes
  Future<List<TVModel>>? _carouselFuture;

  @override
  void initState() {
    super.initState();
    _carouselFuture = _apiService.getTVData(TvType.airingTody);
    _scrollController.addListener(() {
      final opacity = (_scrollController.offset / 200).clamp(0.0, 1.0);
      if ((opacity - _appBarOpacity).abs() > 0.01) {
        setState(() => _appBarOpacity = opacity);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToSeeAll(SeeAllTvType type) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => TVSeeAllScreen(tvType: type),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D1A),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: const Color(0xFF050D1A).withValues(alpha: _appBarOpacity),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'CINE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        TextSpan(
                          text: 'VAULT',
                          style: TextStyle(
                            color: Color(0xFF00D4C8),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const TVSearchScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const TVGenresScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 350),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Carousel
          SliverToBoxAdapter(
            child: FutureBuilder<List<TVModel>>(
              future: _carouselFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final List<TVModel> shows = snapshot.data ?? [];
                  return TVCarusel(tvModelList: shows);
                }
                return const SizedBox(
                  height: 460,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00D4C8),
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
            ),
          ),

          // Sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _SectionHeader(
                    title: 'Popular Shows',
                    icon: Icons.local_fire_department_rounded,
                    onSeeAll: () => _goToSeeAll(SeeAllTvType.popular),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 210,
                    child: TvCategory(
                      key: const ValueKey('tv_popular'), // ✅ fix
                      tvType: TvType.popular,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Top Rated',
                    icon: Icons.star_rounded,
                    onSeeAll: () => _goToSeeAll(SeeAllTvType.topRated),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 210,
                    child: TvCategory(
                      key: const ValueKey('tv_topRated'), // ✅ fix
                      tvType: TvType.topRated,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'On The Air',
                    icon: Icons.sensors_rounded,
                    onSeeAll: () => _goToSeeAll(SeeAllTvType.onTheAir),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 210,
                    child: TvCategory(
                      key: const ValueKey('tv_onTheAir'), // ✅ fix
                      tvType: TvType.onTheAir,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D4C8), size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  'See all',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
