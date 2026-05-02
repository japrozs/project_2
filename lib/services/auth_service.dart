import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  AuthService() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadUserModel(user.uid);
      } else {
        _userModel = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserModel(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user model: $e');
    }
  }

  Future<UserModel?> getUserModel() async {
    if (_userModel != null) return _userModel;
    final user = _auth.currentUser;
    if (user == null) return null;
    await _loadUserModel(user.uid);
    return _userModel;
  }

  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user?.updateDisplayName(displayName.trim());

      final userModel = UserModel(
        uid: credential.user!.uid,
        displayName: displayName.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );

      await _db
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toMap());

      _userModel = userModel;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  Future<String?> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Not authenticated.';

      if (displayName != null) await user.updateDisplayName(displayName);
      if (photoURL != null) await user.updatePhotoURL(photoURL);

      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;

      if (updates.isNotEmpty) {
        await _db.collection('users').doc(user.uid).update(updates);
        await _loadUserModel(user.uid);
      }

      return null;
    } catch (e) {
      return 'Failed to update profile.';
    }
  }

  Future<void> incrementHikeStats({
    required double distanceMiles,
    required List<String> newBadges,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'totalHikes': FieldValue.increment(1),
      'totalMiles': FieldValue.increment(distanceMiles),
      if (newBadges.isNotEmpty)
        'badgesEarned': FieldValue.arrayUnion(newBadges),
    });

    await _loadUserModel(user.uid);
  }

  Future<void> addBadge(String badgeId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'badgesEarned': FieldValue.arrayUnion([badgeId]),
    });

    await _loadUserModel(user.uid);
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
