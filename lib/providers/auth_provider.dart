import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
export '../services/auth_service.dart' show SocialSignInResult, GoogleSignInResult;

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authService.userStream.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        _currentUser = await _authService.getUserData(firebaseUser.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserType userType,
    required String phone,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentUser = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        userType: userType,
      );

      _setLoading(false);
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _errorMessage = _getAuthErrorMessage(e.code);
      return false;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'An unexpected error occurred';
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _setLoading(false);
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _errorMessage = _getAuthErrorMessage(e.code);
      return false;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'An unexpected error occurred';
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Error signing out';
    } finally {
      _setLoading(false);
    }
  }

  Future<SocialSignInResult> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final result = await _authService.signInWithGoogle();
      if (result.isExisting) {
        _currentUser = result.appUser;
        notifyListeners();
      }
      return result;
    } catch (e) {
      _errorMessage = 'Google Sign-In failed. Please try again.';
      notifyListeners();
      return SocialSignInResult.cancelled();
    } finally {
      _setLoading(false);
    }
  }

  Future<SocialSignInResult> signInWithApple() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final result = await _authService.signInWithApple();
      if (result.isExisting) {
        _currentUser = result.appUser;
        notifyListeners();
      }
      return result;
    } catch (e) {
      _errorMessage = 'Apple Sign-In failed. Please try again.';
      notifyListeners();
      return SocialSignInResult.cancelled();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createSocialUser({
    required firebaseUser,
    required UserType userType,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.createSocialUser(
        firebaseUser: firebaseUser,
        userType: userType,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create account.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Backwards-compatible alias for existing callers.
  Future<bool> createGoogleUser({
    required firebaseUser,
    required UserType userType,
  }) =>
      createSocialUser(firebaseUser: firebaseUser, userType: userType);

  /// Permanently deletes the current account and its data.
  /// [password] is required only for email/password users.
  Future<bool> deleteAccount({String? password}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.deleteAccount(password: password);
      _currentUser = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Could not delete the account. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _errorMessage = _getAuthErrorMessage(e.code);
      return false;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'An unexpected error occurred';
      return false;
    }
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    _setLoading(true);
    try {
      await _authService.updateUserProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );

      // Refresh current user data
      if (_currentUser != null) {
        _currentUser = await _authService.getUserData(_currentUser!.uid);
      }
    } catch (e) {
      _errorMessage = 'Error updating profile';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'The email address is invalid';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication error: $code';
    }
  }
}
