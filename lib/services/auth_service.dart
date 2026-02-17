import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'firestore_wrapper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user stream
  Stream<User?> get userStream => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserType userType,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) return null;

      // Update display name
      await user.updateDisplayName(displayName);

      // Create user document in Firestore using wrapper
      AppUser appUser = AppUser(
        uid: user.uid,
        email: email,
        userType: userType,
        displayName: displayName,
        createdAt: DateTime.now(),
        isVerified: false,
      );

      await FirestoreWrapper.setDocument('users', user.uid, appUser.toMap());

      // Send email verification
      await user.sendEmailVerification();

      return appUser;
    } catch (e, stackTrace) {
      print('Error in sign up: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) return null;

      // Get user data from Firestore using wrapper
      DocumentSnapshot doc =
          await FirestoreWrapper.getDocument('users', user.uid);

      if (!doc.exists) {
        print(
            'ERROR: User document does not exist in Firestore for UID: ${user.uid}');
        return null;
      }

      return AppUser.fromFirestore(doc);
    } catch (e, stackTrace) {
      print('Error in sign in: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get user data
  Future<AppUser?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await FirestoreWrapper.getDocument('users', uid);
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e, stackTrace) {
      print('Error getting user data: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e, stackTrace) {
      print('Error signing out: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e, stackTrace) {
      print('Error resetting password: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      User? user = currentUser;
      if (user == null) return;

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Update in Firestore using wrapper
      Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (updates.isNotEmpty) {
        await FirestoreWrapper.updateDocument('users', user.uid, updates);
      }
    } catch (e, stackTrace) {
      print('Error updating profile: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
