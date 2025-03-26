import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveAuthService {
  static final GoogleDriveAuthService _instance =
      GoogleDriveAuthService._internal();
  factory GoogleDriveAuthService() => _instance;

  GoogleDriveAuthService._internal() {
    _initializeGoogleSignIn();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  drive.DriveApi? _driveApi;
  GoogleSignInAccount? _currentUser;

  // Listenable for authentication state changes
  final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

  void _initializeGoogleSignIn() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
      _updateAuthState(account != null);
    });
  }

  void _updateAuthState(bool isSignedIn) {
    authStateNotifier.value = isSignedIn;
    _persistAuthState(isSignedIn);
  }

  void _persistAuthState(bool isSignedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('google_drive_signed_in', isSignedIn);
  }

  Future<bool> checkPreviousSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    final wasSignedIn = prefs.getBool('google_drive_signed_in') ?? false;

    if (wasSignedIn) {
      return await silentSignIn();
    }
    return false;
  }

  Future<bool> silentSignIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        await _initializeDriveApi(account);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Silent sign-in error: $e');
      return false;
    }
  }

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _initializeDriveApi(account);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Sign-in error: $e');
      return false;
    }
  }

  Future<void> _initializeDriveApi(GoogleSignInAccount account) async {
    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient != null) {
      _driveApi = drive.DriveApi(authClient);
    }
  }

  drive.DriveApi? getDriveApi() {
    if (!isSignedIn) return null;
    return _driveApi;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _driveApi = null;
    _currentUser = null;
    _updateAuthState(false);
  }

  bool get isSignedIn => _currentUser != null;

  GoogleSignInAccount? get currentUser => _currentUser;

  drive.DriveApi? get driveApi => _driveApi;

  String? get userEmail => _currentUser?.email;

  String? get userName => _currentUser?.displayName;
}
