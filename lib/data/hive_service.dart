import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

// Lightweight local cache for the logged-in user's profile data + wishlist.
// Keeps the app fast — no Firestore round-trip on every launch.
class HiveService {
  static const _boxName = 'cinevault_user';
  static late Box _box;

  // Init (call once in main.dart before runApp)
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // Profile data
  static String get name => _box.get('name', defaultValue: '');
  static String get email => _box.get('email', defaultValue: '');
  static String get avatarPath => _box.get(
    'avatarPath',
    defaultValue: 'assets/images/avatar_null_profile_picture.png',
  );
  static bool get isProfileSetup =>
      _box.get('profileSetup', defaultValue: false);

  static Future<void> saveProfile({
    required String name,
    required String email,
    required String avatarPath,
  }) async {
    await _box.putAll({
      'name': name,
      'email': email,
      'avatarPath': avatarPath,
      'profileSetup': true,
    });
  }

  // Restore profile from a Firestore snapshot
  static Future<void> restoreFromMap(Map<String, dynamic> data) async {
    await _box.putAll({
      'name': data['name'] ?? '',
      'email': data['email'] ?? '',
      'avatarPath':
          data['avatarPath'] ?? 'assets/images/avatar_null_profile_picture.png',
      'profileSetup': data['profileSetup'] ?? false,
    });

    // Restore wishlist movies if present
    if (data['wishlistMovies'] != null) {
      final movies = data['wishlistMovies'];
      if (movies is List) {
        await _box.put('wishlistMovies', jsonEncode(movies));
      } else if (movies is String) {
        await _box.put('wishlistMovies', movies);
      }
    }

    // Restore wishlist TV shows if present
    if (data['wishlistTV'] != null) {
      final tv = data['wishlistTV'];
      if (tv is List) {
        await _box.put('wishlistTV', jsonEncode(tv));
      } else if (tv is String) {
        await _box.put('wishlistTV', tv);
      }
    }
  }

  // Check whether Hive was wiped (e.g. fresh install / reinstall)
  static bool isHiveEmpty() => !_box.containsKey('profileSetup');

  // Clear local data on logout
  static Future<void> clear() async => _box.clear();

  // Wishlist: Movies
  // Returns raw JSON list of saved movie maps.
  static List<Map<String, dynamic>> getWishlistMovies() {
    final raw = _box.get('wishlistMovies', defaultValue: '[]') as String;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static bool isMovieWishlisted(int movieId) {
    return getWishlistMovies().any((m) => m['id'] == movieId);
  }

  static Future<void> addMovieToWishlist(Map<String, dynamic> movieJson) async {
    final list = getWishlistMovies();
    if (list.any((m) => m['id'] == movieJson['id'])) return;
    list.add(movieJson);
    await _box.put('wishlistMovies', jsonEncode(list));
  }

  static Future<void> removeMovieFromWishlist(int movieId) async {
    final list = getWishlistMovies();
    list.removeWhere((m) => m['id'] == movieId);
    await _box.put('wishlistMovies', jsonEncode(list));
  }

  // Wishlist: TV Shows
  static List<Map<String, dynamic>> getWishlistTV() {
    final raw = _box.get('wishlistTV', defaultValue: '[]') as String;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static bool isTVWishlisted(int tvId) {
    return getWishlistTV().any((t) => t['id'] == tvId);
  }

  static Future<void> addTVToWishlist(Map<String, dynamic> tvJson) async {
    final list = getWishlistTV();
    if (list.any((t) => t['id'] == tvJson['id'])) return;
    list.add(tvJson);
    await _box.put('wishlistTV', jsonEncode(list));
  }

  static Future<void> removeTVFromWishlist(int tvId) async {
    final list = getWishlistTV();
    list.removeWhere((t) => t['id'] == tvId);
    await _box.put('wishlistTV', jsonEncode(list));
  }
}
