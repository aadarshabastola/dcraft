import 'package:dcraft/services/drive_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class GoogleDriveAuthProvider extends ChangeNotifier {
  final GoogleDriveAuthService _authService = GoogleDriveAuthService();
  static const String _authKey = 'google_drive_auth';
  bool _isInitialized = false;
  drive.DriveApi? _driveApi;

  GoogleDriveAuthService get authService => _authService;
  bool get isInitialized => _isInitialized;
  drive.DriveApi? get driveApi => _driveApi;

  GoogleDriveAuthProvider() {
    _initializeAuth().then((_) async {
      if (_authService.isSignedIn) {
        _driveApi = await _authService.getDriveApi();
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> _initializeAuth() async {
    // Load saved auth state first
    final prefs = await SharedPreferences.getInstance();
    final savedAuth = prefs.getBool(_authKey) ?? false;

    if (savedAuth) {
      await _authService.checkPreviousSignIn();
      _driveApi = await _authService.getDriveApi();
    }

    _authService.authStateNotifier.addListener(_handleAuthStateChange);
  }

  void _handleAuthStateChange() async {
    if (_authService.isSignedIn) {
      _driveApi = await _authService.getDriveApi();
    } else {
      _driveApi = null;
    }
    notifyListeners();
    _saveAuthState();
  }

  Future<void> _saveAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, _authService.isSignedIn);
  }

  Future<bool> signIn() async {
    final result = await _authService.signIn();
    if (result) {
      _driveApi = await _authService.getDriveApi();
      await _saveAuthState();
    }
    notifyListeners();
    return result;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _driveApi = null;
    await _saveAuthState();
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.authStateNotifier.removeListener(_handleAuthStateChange);
    super.dispose();
  }
}
