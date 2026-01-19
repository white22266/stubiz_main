import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  // 1. Register with UTHM Email Validation
  static Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final emailTrimmed = email.trim().toLowerCase();

    // Strict UTHM Email Check
    if (!emailTrimmed.endsWith('@student.uthm.edu.my') &&
        !emailTrimmed.endsWith('@uthm.edu.my')) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message:
            'Registration is restricted to UTHM students (@student.uthm.edu.my).',
      );
    }

    if (password.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Password must be at least 6 chars.',
      );
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: emailTrimmed,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    await cred.user!.sendEmailVerification();

    // Create Profile in Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'email': emailTrimmed,
      'displayName': displayName,
      'role': 'student', // Default role
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. Login with Role & Verification Check
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (!cred.user!.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'unverified',
        message: 'Please verify your email first.',
      );
    }

    // Check if account is active/banned
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (doc.exists && doc.data()?['isActive'] == false) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'disabled',
        message: 'Your account has been disabled by Admin.',
      );
    }
  }

  static Future<void> logout() => _auth.signOut();

  // Helper: Get Current Role
  static Future<String> getCurrentRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'guest';
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['role'] ?? 'student';
  }
}
