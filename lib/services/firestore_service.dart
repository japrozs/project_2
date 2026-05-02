import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/local_trails.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Trails (local — no network call) ────────────────────────────────────

  Stream<List<TrailModel>> getTrails({String? difficulty, String? region}) {
    var trails = LocalTrails.all;

    if (difficulty != null && difficulty != 'All') {
      trails = trails.where((t) => t.difficulty == difficulty).toList();
    }
    if (region != null && region.isNotEmpty) {
      trails = trails.where((t) => t.region == region).toList();
    }

    return Stream.value(trails);
  }

  Future<TrailModel?> getTrail(String trailId) async {
    return LocalTrails.findById(trailId);
  }

  Future<void> updateTrailRiskScore({
    required String trailId,
    required int score,
    required String level,
  }) async {
    await _db.collection('trails').doc(trailId).update({
      'riskScore': score,
      'riskLevel': level,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> seedTrailsIfEmpty() async {
    final snap = await _db.collection('trails').limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final trails = [
      {
        'name': 'Appalachian Trail - Springer Mountain',
        'location': const GeoPoint(34.6275, -84.1938),
        'difficulty': 'Moderate',
        'lengthMiles': 8.4,
        'elevationFt': 3782,
        'riskScore': 25,
        'riskLevel': 'Low',
        'lastUpdated': FieldValue.serverTimestamp(),
        'description':
            'The southern terminus of the Appalachian Trail. A classic Georgia hike with beautiful forest scenery.',
        'imageURL': '',
        'state': 'Georgia',
        'region': 'North Georgia',
      },
      {
        'name': 'Blood Mountain Loop',
        'location': const GeoPoint(34.7421, -83.9338),
        'difficulty': 'Hard',
        'lengthMiles': 6.1,
        'elevationFt': 4461,
        'riskScore': 45,
        'riskLevel': 'Moderate',
        'lastUpdated': FieldValue.serverTimestamp(),
        'description':
            'The highest peak on the Georgia AT section. Rocky summit with panoramic views.',
        'imageURL': '',
        'state': 'Georgia',
        'region': 'North Georgia',
      },
      {
        'name': 'Stone Mountain Trail',
        'location': const GeoPoint(33.8057, -84.1457),
        'difficulty': 'Easy',
        'lengthMiles': 1.3,
        'elevationFt': 1686,
        'riskScore': 10,
        'riskLevel': 'Low',
        'lastUpdated': FieldValue.serverTimestamp(),
        'description':
            'A short but rewarding summit hike up the exposed granite face of Stone Mountain.',
        'imageURL': '',
        'state': 'Georgia',
        'region': 'Metro Atlanta',
      },
      {
        'name': 'Amicalola Falls Trail',
        'location': const GeoPoint(34.5673, -84.2459),
        'difficulty': 'Moderate',
        'lengthMiles': 4.2,
        'elevationFt': 2100,
        'riskScore': 30,
        'riskLevel': 'Low',
        'lastUpdated': FieldValue.serverTimestamp(),
        'description':
            'Trail through Amicalola Falls State Park, passing the tallest cascading waterfall east of the Mississippi.',
        'imageURL': '',
        'state': 'Georgia',
        'region': 'North Georgia',
      },
      {
        'name': 'Kennesaw Mountain Summit',
        'location': const GeoPoint(33.9898, -84.5780),
        'difficulty': 'Easy',
        'lengthMiles': 2.5,
        'elevationFt': 1808,
        'riskScore': 15,
        'riskLevel': 'Low',
        'lastUpdated': FieldValue.serverTimestamp(),
        'description':
            'Popular Civil War battlefield hike near Marietta with great city views from the summit.',
        'imageURL': '',
        'state': 'Georgia',
        'region': 'Metro Atlanta',
      },
      {
        'name': 'Cloudland Canyon Waterfalls',
        'location': const GeoPoint(34.8374, -85.4835),
        'difficulty': 'Hard',
        'lengthMiles': 5.0,
        'elevationFt': 1980,
        'riskScore': 55,
        'riskLevel': 'Moderate',
        'lastUpdated': FieldValue.serverTimestamp(),
        'description':
            'Steep canyon descent with two waterfall overlooks. Stairs and switchbacks throughout.',
        'imageURL': '',
        'state': 'Georgia',
        'region': 'Northwest Georgia',
      },
    ];

    final batch = _db.batch();
    for (final t in trails) {
      batch.set(_db.collection('trails').doc(), t);
    }
    await batch.commit();
  }

  // ─── Hikes ────────────────────────────────────────────────────────────────

  Stream<List<HikeModel>> getUserHikes(String userId) {
    return _db
        .collection('hikes')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => HikeModel.fromFirestore(d)).toList());
  }

  Future<String> addHike(HikeModel hike) async {
    final ref = await _db.collection('hikes').add(hike.toMap());
    return ref.id;
  }

  Future<void> deleteHike(String hikeId) async {
    await _db.collection('hikes').doc(hikeId).delete();
  }

  // ─── Reports ──────────────────────────────────────────────────────────────

  Stream<List<ReportModel>> getTrailReports(String trailId) {
    return _db
        .collection('reports')
        .where('trailId', isEqualTo: trailId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ReportModel.fromFirestore(d)).toList());
  }

  Future<List<ReportModel>> getRecentReports(
      String trailId, DateTime since) async {
    final snap = await _db
        .collection('reports')
        .where('trailId', isEqualTo: trailId)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(since))
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((d) => ReportModel.fromFirestore(d)).toList();
  }

  Future<void> addReport(ReportModel report) async {
    await _db.collection('reports').add(report.toMap());
  }

  // ─── Posts ────────────────────────────────────────────────────────────────

  Stream<List<PostModel>> getCommunityFeed() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PostModel.fromFirestore(d)).toList());
  }

  Future<void> addPost(PostModel post) async {
    await _db.collection('posts').add(post.toMap());
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool isLiked,
  }) async {
    await _db.collection('posts').doc(postId).update({
      'likes': isLiked
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  // ─── Comments ─────────────────────────────────────────────────────────────

  Stream<List<CommentModel>> getComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CommentModel.fromFirestore(d)).toList());
  }

  Future<void> addComment(CommentModel comment) async {
    final batch = _db.batch();
    final commentRef = _db
        .collection('posts')
        .doc(comment.postId)
        .collection('comments')
        .doc();
    batch.set(commentRef, comment.toMap());
    batch.update(_db.collection('posts').doc(comment.postId), {
      'commentsCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
  }

  Future<void> markNotificationRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({'isRead': true});
  }

  Future<void> addNotification(NotificationModel notif) async {
    await _db.collection('notifications').add(notif.toMap());
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─── User ─────────────────────────────────────────────────────────────────

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }
}
