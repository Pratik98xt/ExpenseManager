import 'dart:async';
import 'package:expense_manager_app/services/auth_service.dart';
import 'package:expense_manager_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<User?>? _authSubscription;

  User? _currentUser;
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  String get userName => _userName.isNotEmpty ? _userName : (_currentUser?.displayName ?? 'User');
  String get userEmail => _userEmail.isNotEmpty ? _userEmail : (_currentUser?.email ?? '');
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  AuthController() {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      loadUserProfile();
    }
    _authSubscription = _authService.authStateChanges.listen((user) {
      _currentUser = user;
      if (user != null) {
        loadUserProfile();
      } else {
        _userName = '';
        _userEmail = '';
        notifyListeners();
      }
    });
  }

  /// Load user profile from Firestore users/{uid}
  Future<void> loadUserProfile() async {
    if (_currentUser == null) return;
    try {
      final profile = await _firestoreService.getUserProfile(_currentUser!.uid);
      if (profile != null) {
        _userName = profile['name']?.toString() ?? '';
        _userEmail = profile['email']?.toString() ?? _currentUser!.email ?? '';
        notifyListeners();
      }
    } catch (_) {
      // Quietly ignore profile fetch errors on startup
    }
  }

  /// Sign in with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signIn(
        email: email,
        password: password,
      );
      _currentUser = credential.user;
      if (_currentUser != null) {
        await loadUserProfile();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign up with name, email, and password
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signUp(
        email: email,
        password: password,
      );
      _currentUser = credential.user;
      if (_currentUser != null) {
        // Save user profile to Firestore
        await _firestoreService.createUserProfile(
          uid: _currentUser!.uid,
          name: name,
          email: email,
        );
        _userName = name;
        _userEmail = email;

        // Seed default categories for convenient out-of-the-box experience
        await _firestoreService.seedDefaultCategoriesIfEmpty(_currentUser!.uid);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
      _currentUser = null;
      _userName = '';
      _userEmail = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

