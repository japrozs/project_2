import 'package:cloud_firestore/cloud_firestore.dart';

// ─── UserModel ───────────────────────────────────────────────────────────────

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String photoURL;
  final int totalHikes;
  final double totalMiles;
  final List<String> badgesEarned;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL = '',
    this.totalHikes = 0,
    this.totalMiles = 0.0,
    this.badgesEarned = const [],
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoURL: data['photoURL'] ?? '',
      totalHikes: data['totalHikes'] ?? 0,
      totalMiles: (data['totalMiles'] ?? 0).toDouble(),
      badgesEarned: List<String>.from(data['badgesEarned'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'photoURL': photoURL,
        'totalHikes': totalHikes,
        'totalMiles': totalMiles,
        'badgesEarned': badgesEarned,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    int? totalHikes,
    double? totalMiles,
    List<String>? badgesEarned,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoURL: photoURL ?? this.photoURL,
      totalHikes: totalHikes ?? this.totalHikes,
      totalMiles: totalMiles ?? this.totalMiles,
      badgesEarned: badgesEarned ?? this.badgesEarned,
      createdAt: createdAt,
    );
  }
}

class HikeModel {
  final String id;
  final String userId;
  final String trailId;
  final String title;
  final double distance;
  final int durationMinutes;
  final DateTime date;
  final String notes;
  final List<String> photoURLs;
  final bool isPublic;
  final DateTime createdAt;
  final int elevationGain;

  const HikeModel({
    required this.id,
    required this.userId,
    this.trailId = '',
    required this.title,
    required this.distance,
    required this.durationMinutes,
    required this.date,
    this.notes = '',
    this.photoURLs = const [],
    this.isPublic = true,
    required this.createdAt,
    this.elevationGain = 0,
  });

  factory HikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HikeModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      trailId: data['trailId'] ?? '',
      title: data['title'] ?? '',
      distance: (data['distance'] ?? 0).toDouble(),
      durationMinutes: data['durationMinutes'] ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] ?? '',
      photoURLs: List<String>.from(data['photoURLs'] ?? []),
      isPublic: data['isPublic'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      elevationGain: data['elevationGain'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'trailId': trailId,
        'title': title,
        'distance': distance,
        'durationMinutes': durationMinutes,
        'date': Timestamp.fromDate(date),
        'notes': notes,
        'photoURLs': photoURLs,
        'isPublic': isPublic,
        'createdAt': Timestamp.fromDate(createdAt),
        'elevationGain': elevationGain,
      };

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}
