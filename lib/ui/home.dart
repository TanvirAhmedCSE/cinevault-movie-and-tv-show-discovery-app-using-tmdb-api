// import 'package:flutter/material.dart';
// import 'movie/movie_page.dart';
// import 'tv/tv_page.dart';
// import 'profile/profile_screen.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
//   int _selectedIndex = 0;
//   late AnimationController _fadeController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeInOut,
//     );
//     _fadeController.forward();
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     super.dispose();
//   }

//   void _onTabChanged(int index) {
//     if (_selectedIndex == index) return;
//     _fadeController.reverse().then((_) {
//       setState(() => _selectedIndex = index);
//       _fadeController.forward();
//     });
//   }

//   Widget _getView() {
//     if (_selectedIndex == 0) return const MoviePage();
//     if (_selectedIndex == 1) return const TVPage();
//     return const ProfileScreen();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0A0F),
//       extendBody: true,
//       body: FadeTransition(opacity: _fadeAnimation, child: _getView()),
//       bottomNavigationBar: _CinematicBottomNav(
//         selectedIndex: _selectedIndex,
//         onTap: _onTabChanged,
//       ),
//     );
//   }
// }

// class _CinematicBottomNav extends StatelessWidget {
//   final int selectedIndex;
//   final ValueChanged<int> onTap;

//   const _CinematicBottomNav({required this.selectedIndex, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFF0A0A0F),
//         border: Border(
//           top: BorderSide(
//             color: Colors.white.withValues(alpha: 0.06),
//             width: 0.5,
//           ),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.8),
//             blurRadius: 20,
//             offset: const Offset(0, -5),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _NavItem(
//                 icon: Icons.movie_filter_rounded,
//                 label: 'Movies',
//                 isSelected: selectedIndex == 0,
//                 onTap: () => onTap(0),
//                 activeColor: const Color(0xFFE50914),
//               ),
//               _NavItem(
//                 icon: Icons.tv_rounded,
//                 label: 'TV Shows',
//                 isSelected: selectedIndex == 1,
//                 onTap: () => onTap(1),
//                 activeColor: const Color(0xFF00D4C8),
//               ),
//               _NavItem(
//                 icon: Icons.person,
//                 label: 'Profile',
//                 isSelected: selectedIndex == 2,
//                 onTap: () => onTap(2),
//                 activeColor: const Color(0xFF8B5CF6),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _NavItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool isSelected;
//   final VoidCallback onTap;
//   final Color activeColor;

//   const _NavItem({
//     required this.icon,
//     required this.label,
//     required this.isSelected,
//     required this.onTap,
//     required this.activeColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       behavior: HitTestBehavior.opaque,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeInOut,
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(30),
//           color: isSelected
//               ? activeColor.withValues(alpha: 0.12)
//               : Colors.transparent,
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             AnimatedScale(
//               scale: isSelected ? 1.1 : 1.0,
//               duration: const Duration(milliseconds: 250),
//               child: Icon(
//                 icon,
//                 color: isSelected ? activeColor : const Color(0xFF6B6B80),
//                 size: 22,
//               ),
//             ),
//             if (isSelected) ...[
//               const SizedBox(width: 8),
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: activeColor,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   letterSpacing: 0.3,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'movie/movie_page.dart';
import 'tv/tv_page.dart';
import 'wishlist/wishlist_screen.dart';
import 'profile/profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (_selectedIndex == index) return;
    _fadeController.reverse().then((_) {
      setState(() => _selectedIndex = index);
      _fadeController.forward();
    });
  }

  Widget _getView() {
    if (_selectedIndex == 0) return const MoviePage();
    if (_selectedIndex == 1) return const TVPage();
    if (_selectedIndex == 2) return const WishlistScreen();
    return const ProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBody: true,
      body: FadeTransition(opacity: _fadeAnimation, child: _getView()),
      bottomNavigationBar: _CinematicBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onTabChanged,
      ),
    );
  }
}

class _CinematicBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _CinematicBottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.movie_filter_rounded,
                label: 'Movies',
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
                activeColor: const Color(0xFFE50914),
              ),
              _NavItem(
                icon: Icons.tv_rounded,
                label: 'TV Shows',
                isSelected: selectedIndex == 1,
                onTap: () => onTap(1),
                activeColor: const Color(0xFF00D4C8),
              ),
              _NavItem(
                icon: Icons.bookmark_rounded,
                label: 'Wishlist',
                isSelected: selectedIndex == 2,
                onTap: () => onTap(2),
                activeColor: const Color(0xFF22C55E),
              ),
              _NavItem(
                icon: Icons.person,
                label: 'Profile',
                isSelected: selectedIndex == 3,
                onTap: () => onTap(3),
                activeColor: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                color: isSelected ? activeColor : const Color(0xFF6B6B80),
                size: 22,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
