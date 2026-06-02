import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? get currentUid => _auth.currentUser?.uid;
  static String? get currentEmail => _auth.currentUser?.email;

  // Sign Up
  static Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  //  Sign In
  static Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  //  Sync email field in Firestore
  static Future<void> syncEmail(String uid, String email) async {
    try {
      await _db.collection('users').doc(uid).update({
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-fatal — fire & forget
    }
  }

  //  Sign Out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  //  Save user profile to Firestore
  static Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String avatarPath,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': currentEmail ?? '',
      'avatarPath': avatarPath,
      'profileSetup': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  //  Fetch user profile from Firestore
  // Returns profile fields + wishlistMovies + wishlistTV (decoded to List).
  static Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data()!;

      // Decode wishlist fields if stored as JSON strings
      if (data['wishlistMovies'] is String) {
        try {
          data['wishlistMovies'] = jsonDecode(data['wishlistMovies'] as String);
        } catch (_) {
          data['wishlistMovies'] = [];
        }
      }
      if (data['wishlistTV'] is String) {
        try {
          data['wishlistTV'] = jsonDecode(data['wishlistTV'] as String);
        } catch (_) {
          data['wishlistTV'] = [];
        }
      }

      return data;
    } catch (_) {
      return null;
    }
  }

  //  Wishlist: save entire movie wishlist to Firestore
  static Future<void> saveWishlistMovies(
    String uid,
    List<Map<String, dynamic>> movies,
  ) async {
    try {
      await _db.collection('users').doc(uid).set({
        'wishlistMovies': jsonEncode(movies),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-fatal
    }
  }

  //  Wishlist: save entire TV wishlist to Firestore
  static Future<void> saveWishlistTV(
    String uid,
    List<Map<String, dynamic>> tvShows,
  ) async {
    try {
      await _db.collection('users').doc(uid).set({
        'wishlistTV': jsonEncode(tvShows),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-fatal
    }
  }

  //  Human-readable auth errors
  static String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
