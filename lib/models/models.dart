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
