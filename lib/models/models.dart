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

class TrailModel {
  final String id;
  final String name;
  final GeoPoint location;
  final String difficulty;
  final double lengthMiles;
  final int elevationFt;
  final int riskScore;
  final String riskLevel;
  final DateTime lastUpdated;
  final String description;
  final String imageURL;
  final String state;
  final String region;

  const TrailModel({
    required this.id,
    required this.name,
    required this.location,
    required this.difficulty,
    required this.lengthMiles,
    this.elevationFt = 0,
    this.riskScore = 0,
    this.riskLevel = 'Low',
    required this.lastUpdated,
    this.description = '',
    this.imageURL = '',
    this.state = '',
    this.region = '',
  });

  factory TrailModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrailModel(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      difficulty: data['difficulty'] ?? 'Easy',
      lengthMiles: (data['lengthMiles'] ?? 0).toDouble(),
      elevationFt: data['elevationFt'] ?? 0,
      riskScore: data['riskScore'] ?? 0,
      riskLevel: data['riskLevel'] ?? 'Low',
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] ?? '',
      imageURL: data['imageURL'] ?? '',
      state: data['state'] ?? '',
      region: data['region'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'location': location,
        'difficulty': difficulty,
        'lengthMiles': lengthMiles,
        'elevationFt': elevationFt,
        'riskScore': riskScore,
        'riskLevel': riskLevel,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
        'description': description,
        'imageURL': imageURL,
        'state': state,
        'region': region,
      };
}
