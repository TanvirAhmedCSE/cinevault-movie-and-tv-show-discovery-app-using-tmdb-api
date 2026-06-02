import '../data/firebase_service.dart';
import '../data/hive_service.dart';
import '../model/movie_model.dart';
import '../model/tv_model.dart';

// Centralised wishlist operations.
// Every method updates BOTH Hive (local) and Firestore (remote).
class WishlistService {
  // Movies
  static bool isMovieWishlisted(int id) => HiveService.isMovieWishlisted(id);

  static Future<void> addMovie(MovieModel movie) async {
    await HiveService.addMovieToWishlist(movie.toJson());
    _syncMovies();
  }

  static Future<void> removeMovie(int movieId) async {
    await HiveService.removeMovieFromWishlist(movieId);
    _syncMovies();
  }

  static List<MovieModel> getMovies() {
    return HiveService.getWishlistMovies()
        .map((j) => MovieModel.fromJson(j))
        .toList();
  }

  // TV Shows
  static bool isTVWishlisted(int id) => HiveService.isTVWishlisted(id);

  static Future<void> addTV(TVModel tv) async {
    await HiveService.addTVToWishlist(tv.toJson());
    _syncTV();
  }

  static Future<void> removeTV(int tvId) async {
    await HiveService.removeTVFromWishlist(tvId);
    _syncTV();
  }

  static List<TVModel> getTV() {
    return HiveService.getWishlistTV().map((j) => TVModel.fromJson(j)).toList();
  }

  // Firestore sync (fire-and-forget)
  static void _syncMovies() {
    final uid = FirebaseService.currentUid;
    if (uid == null) return;
    FirebaseService.saveWishlistMovies(uid, HiveService.getWishlistMovies());
  }

  static void _syncTV() {
    final uid = FirebaseService.currentUid;
    if (uid == null) return;
    FirebaseService.saveWishlistTV(uid, HiveService.getWishlistTV());
  }
}
