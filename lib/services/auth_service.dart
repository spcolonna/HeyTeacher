import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/app_user.dart';
import 'firestore_wrapper.dart';
import 'google_calendar_service.dart';
import 'storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storage = StorageService();

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

  // Sign in with Google (also grants Calendar scope via GoogleCalendarService)
  Future<SocialSignInResult> signInWithGoogle() async {
    try {
      final credential = await GoogleCalendarService.getFirebaseCredential();
      if (credential == null) return SocialSignInResult.cancelled();

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) return SocialSignInResult.cancelled();

      final isNew = result.additionalUserInfo?.isNewUser ?? false;

      if (!isNew) {
        final doc = await FirestoreWrapper.getDocument('users', user.uid);
        if (doc.exists) {
          return SocialSignInResult.existing(AppUser.fromFirestore(doc));
        }
      }

      // New user — caller must pick UserType then call createSocialUser()
      return SocialSignInResult.newUser(user);
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Apple (required by App Store guideline 4.8)
  Future<SocialSignInResult> signInWithApple() async {
    try {
      // Apple requires a nonce: we send the SHA-256 hash and verify with the raw value.
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final result = await _auth.signInWithCredential(oauthCredential);
      final user = result.user;
      if (user == null) return SocialSignInResult.cancelled();

      final isNew = result.additionalUserInfo?.isNewUser ?? false;

      if (!isNew) {
        final doc = await FirestoreWrapper.getDocument('users', user.uid);
        if (doc.exists) {
          return SocialSignInResult.existing(AppUser.fromFirestore(doc));
        }
      }

      // Apple only returns the name on the FIRST sign-in — persist it now.
      final appleName = [appleCredential.givenName, appleCredential.familyName]
          .where((p) => p != null && p.isNotEmpty)
          .join(' ');
      if (appleName.isNotEmpty &&
          (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName(appleName);
        await user.reload();
      }

      // New user — caller must pick UserType then call createSocialUser()
      return SocialSignInResult.newUser(_auth.currentUser ?? user);
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled the Apple sheet
      if (e.code == AuthorizationErrorCode.canceled) {
        return SocialSignInResult.cancelled();
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Finalize a new social (Google/Apple) user after they pick teacher/institution
  Future<AppUser> createSocialUser({
    required User firebaseUser,
    required UserType userType,
  }) async {
    final appUser = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      userType: userType,
      displayName: firebaseUser.displayName ?? 'User',
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      isVerified: true,
    );
    await FirestoreWrapper.setDocument('users', firebaseUser.uid, appUser.toMap());
    return appUser;
  }

  // Backwards-compatible alias (kept for existing callers)
  Future<AppUser> createGoogleUser({
    required User firebaseUser,
    required UserType userType,
  }) =>
      createSocialUser(firebaseUser: firebaseUser, userType: userType);

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

  // Permanently delete the current account and its data (App Store guideline 5.1.1).
  // [password] is only required to re-authenticate email/password users.
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // Best-effort cleanup of the user's Firestore documents and stored files.
    await _deleteUserData(uid);

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _reauthenticate(user, password);
        await user.delete();
      } else {
        rethrow;
      }
    }
  }

  Future<void> _deleteUserData(String uid) async {
    // Stored files (CV, certifications, photos, etc.) — best-effort.
    try {
      await _storage.deleteUserFiles(uid);
    } catch (_) {/* ignore */}

    for (final collection in const [
      'users',
      'teacher_profiles',
      'institution_profiles',
    ]) {
      try {
        await FirestoreWrapper.deleteDocument(collection, uid);
      } catch (_) {/* doc may not exist for this user type */}
    }
  }

  Future<void> _reauthenticate(User user, String? password) async {
    final providerId =
        user.providerData.isNotEmpty ? user.providerData.first.providerId : '';

    switch (providerId) {
      case 'google.com':
        final cred = await GoogleCalendarService.getFirebaseCredential();
        if (cred == null) throw Exception('Re-authentication cancelled');
        await user.reauthenticateWithCredential(cred);
        break;
      case 'apple.com':
        final cred = await _appleReauthCredential();
        await user.reauthenticateWithCredential(cred);
        break;
      default: // password
        if (password == null || password.isEmpty) {
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Please enter your password to confirm deletion.',
          );
        }
        final cred = EmailAuthProvider.credential(
          email: user.email ?? '',
          password: password,
        );
        await user.reauthenticateWithCredential(cred);
    }
  }

  Future<OAuthCredential> _appleReauthCredential() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
      nonce: hashedNonce,
    );
    return OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );
  }

  // Cryptographically secure random string for the Apple sign-in nonce.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
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

enum _SocialSignInStatus { existing, newUser, cancelled }

/// Result of a social sign-in (Google or Apple).
class SocialSignInResult {
  final _SocialSignInStatus _status;
  final AppUser? appUser;
  final User? firebaseUser;

  const SocialSignInResult._({
    required _SocialSignInStatus status,
    this.appUser,
    this.firebaseUser,
  }) : _status = status;

  factory SocialSignInResult.existing(AppUser user) =>
      SocialSignInResult._(status: _SocialSignInStatus.existing, appUser: user);

  factory SocialSignInResult.newUser(User user) =>
      SocialSignInResult._(status: _SocialSignInStatus.newUser, firebaseUser: user);

  factory SocialSignInResult.cancelled() =>
      const SocialSignInResult._(status: _SocialSignInStatus.cancelled);

  bool get isExisting => _status == _SocialSignInStatus.existing;
  bool get isNewUser => _status == _SocialSignInStatus.newUser;
  bool get isCancelled => _status == _SocialSignInStatus.cancelled;
}

// Backwards-compatible alias for existing callers.
typedef GoogleSignInResult = SocialSignInResult;
