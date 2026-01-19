import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String role; // 'student' or 'admin'
  final bool isActive;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return UserProfile(
      id: doc.id,
      email: (data['email'] ?? '').toString(),
      displayName: (data['displayName'] ?? '').toString(),
      role: (data['role'] ?? 'student').toString(),
      isActive: data['isActive'] != false, // Default to true if missing
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  bool get isAdmin => role == 'admin';
}
