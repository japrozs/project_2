import '../models/models.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

class BadgeService {
  /// Call after every hike is logged.
  /// Returns the list of newly earned badge IDs.
  static Future<List<String>> checkAndAwardBadges({
    required AuthService authService,
    required FirestoreService firestoreService,
    required double hikeDistanceMiles,
  }) async {
    final user = authService.userModel;
    if (user == null) return [];

    final earned = List<String>.from(user.badgesEarned);
    final newBadges = <String>[];

    final newTotal = user.totalHikes + 1;
    final newMiles = user.totalMiles + hikeDistanceMiles;

    // Hike count badges
    if (newTotal >= 1 && !earned.contains('first_hike')) {
      newBadges.add('first_hike');
    }
    if (newTotal >= 5 && !earned.contains('hike_5')) {
      newBadges.add('hike_5');
    }
    if (newTotal >= 10 && !earned.contains('hike_10')) {
      newBadges.add('hike_10');
    }
    if (newTotal >= 25 && !earned.contains('hike_25')) {
      newBadges.add('hike_25');
    }
    if (newTotal >= 50 && !earned.contains('hike_50')) {
      newBadges.add('hike_50');
    }

    // Mileage badges
    if (newMiles >= 10 && !earned.contains('miles_10')) {
      newBadges.add('miles_10');
    }
    if (newMiles >= 50 && !earned.contains('miles_50')) {
      newBadges.add('miles_50');
    }
    if (newMiles >= 100 && !earned.contains('miles_100')) {
      newBadges.add('miles_100');
    }

    return newBadges;
  }

  /// Check if the user earns the community badge after submitting a report.
  static Future<bool> checkCommunityBadge(AuthService authService) async {
    final user = authService.userModel;
    if (user == null) return false;
    if (user.badgesEarned.contains('community')) return false;
    await authService.addBadge('community');
    return true;
  }

  /// Check photographer badge: earned after uploading photos on 5+ hikes.
  static Future<bool> checkPhotographerBadge({
    required AuthService authService,
    required int hikesWithPhotos,
  }) async {
    final user = authService.userModel;
    if (user == null) return false;
    if (user.badgesEarned.contains('photographer')) return false;
    if (hikesWithPhotos >= 5) {
      await authService.addBadge('photographer');
      return true;
    }
    return false;
  }
}
