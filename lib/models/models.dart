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

// ─── HikeModel ───────────────────────────────────────────────────────────────

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

// ─── TrailModel ──────────────────────────────────────────────────────────────

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

// ─── ReportModel ─────────────────────────────────────────────────────────────

class ReportModel {
  final String id;
  final String userId;
  final String trailId;
  final String conditionType;
  final String description;
  final String photoURL;
  final DateTime timestamp;
  final String userDisplayName;

  const ReportModel({
    required this.id,
    required this.userId,
    required this.trailId,
    required this.conditionType,
    required this.description,
    this.photoURL = '',
    required this.timestamp,
    this.userDisplayName = '',
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      trailId: data['trailId'] ?? '',
      conditionType: data['conditionType'] ?? '',
      description: data['description'] ?? '',
      photoURL: data['photoURL'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userDisplayName: data['userDisplayName'] ?? 'Hiker',
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'trailId': trailId,
        'conditionType': conditionType,
        'description': description,
        'photoURL': photoURL,
        'timestamp': Timestamp.fromDate(timestamp),
        'userDisplayName': userDisplayName,
      };
}

// ─── PostModel ───────────────────────────────────────────────────────────────

class PostModel {
  final String id;
  final String userId;
  final String hikeId;
  final String caption;
  final String photoURL;
  final List<String> likes;
  final int commentsCount;
  final DateTime createdAt;
  final String userDisplayName;
  final String userPhotoURL;

  const PostModel({
    required this.id,
    required this.userId,
    this.hikeId = '',
    required this.caption,
    this.photoURL = '',
    this.likes = const [],
    this.commentsCount = 0,
    required this.createdAt,
    this.userDisplayName = '',
    this.userPhotoURL = '',
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      hikeId: data['hikeId'] ?? '',
      caption: data['caption'] ?? '',
      photoURL: data['photoURL'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      commentsCount: data['commentsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userDisplayName: data['userDisplayName'] ?? '',
      userPhotoURL: data['userPhotoURL'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'hikeId': hikeId,
        'caption': caption,
        'photoURL': photoURL,
        'likes': likes,
        'commentsCount': commentsCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'userDisplayName': userDisplayName,
        'userPhotoURL': userPhotoURL,
      };
}

// ─── NotificationModel ───────────────────────────────────────────────────────

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String message;
  final String trailId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.trailId = '',
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      message: data['message'] ?? '',
      trailId: data['trailId'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type,
        'message': message,
        'trailId': trailId,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ─── CommentModel ────────────────────────────────────────────────────────────

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String userDisplayName;
  final String userPhotoURL;
  final String text;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoURL = '',
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'] ?? '',
      userPhotoURL: data['userPhotoURL'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'userId': userId,
        'userDisplayName': userDisplayName,
        'userPhotoURL': userPhotoURL,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ─── Badge definitions ───────────────────────────────────────────────────────

class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

class AppBadges {
  static const List<BadgeDefinition> all = [
    BadgeDefinition(
      id: 'first_hike',
      name: 'First Steps',
      description: 'Logged your first hike',
      icon: 'boot',
    ),
    BadgeDefinition(
      id: 'hike_5',
      name: 'Trail Starter',
      description: 'Logged 5 hikes',
      icon: 'trail',
    ),
    BadgeDefinition(
      id: 'hike_10',
      name: 'Weekend Warrior',
      description: 'Logged 10 hikes',
      icon: 'mountain',
    ),
    BadgeDefinition(
      id: 'hike_25',
      name: 'Trailblazer',
      description: 'Logged 25 hikes',
      icon: 'fire',
    ),
    BadgeDefinition(
      id: 'hike_50',
      name: 'Summit Seeker',
      description: 'Logged 50 hikes',
      icon: 'flag',
    ),
    BadgeDefinition(
      id: 'miles_10',
      name: '10 Mile Club',
      description: 'Hiked a total of 10 miles',
      icon: 'road',
    ),
    BadgeDefinition(
      id: 'miles_50',
      name: '50 Mile Club',
      description: 'Hiked a total of 50 miles',
      icon: 'map',
    ),
    BadgeDefinition(
      id: 'miles_100',
      name: 'Century Hiker',
      description: 'Hiked a total of 100 miles',
      icon: 'trophy',
    ),
    BadgeDefinition(
      id: 'community',
      name: 'Community Voice',
      description: 'Submitted your first trail report',
      icon: 'people',
    ),
    BadgeDefinition(
      id: 'photographer',
      name: 'Trail Photographer',
      description: 'Uploaded photos on 5 hikes',
      icon: 'camera',
    ),
  ];

  static BadgeDefinition? findById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
