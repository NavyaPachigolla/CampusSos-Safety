import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _firebaseUser;
  AppUser? _currentUser;
  bool _isLoading = true;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;

  AuthService() {
    _initAuthListener();
  }

  User? get firebaseUser => _firebaseUser;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isLoading => _isLoading;
  String? get currentUid => _firebaseUser?.uid;

  void _initAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        await _subscribeToUserDoc(user.uid);
      } else {
        _userDocSubscription?.cancel();
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Auth state listener error: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _subscribeToUserDoc(String uid) async {
    _userDocSubscription?.cancel();
    _userDocSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _currentUser = AppUser.fromFirestore(snapshot);
      } else if (_firebaseUser != null) {
        // Fallback user profile if Firestore document is pending creation
        _currentUser = AppUser(
          uid: _firebaseUser!.uid,
          name: _firebaseUser!.displayName ?? 'Student',
          email: _firebaseUser!.email ?? '',
          college: 'Campus',
          role: 'student',
        );
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (err) {
      debugPrint('User doc snapshot error: $err');
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Register student with Email and Password
  /// Strict requirement: Role is forced to 'student' to prevent privilege escalation.
  Future<AppUser> registerStudent({
    required String name,
    required String email,
    required String password,
    required String college,
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User registration failed: No user returned');
      }

      await user.updateDisplayName(name.trim());

      final appUser = AppUser(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        college: college.trim(),
        role: 'student', // Security requirement: client cannot escalate to admin
        phone: phone?.trim(),
      );

      // Persist to users collection using UID as document ID
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(appUser.toInitialMap());

      _currentUser = appUser;
      notifyListeners();
      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Registration error: ${e.toString()}');
    }
  }

  /// Sign in with Email and Password
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Sign in error: ${e.toString()}');
    }
  }

  /// Update student profile (Name, College, Phone)
  /// Role cannot be modified by ordinary students
  Future<void> updateProfile({
    required String name,
    required String college,
    String? phone,
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('No authenticated user');

    try {
      await _firestore.collection('users').doc(uid).update({
        'name': name.trim(),
        'college': college.trim(),
        if (phone != null) 'phone': phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_firebaseUser != null) {
        await _firebaseUser!.updateDisplayName(name.trim());
      }

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          name: name.trim(),
          college: college.trim(),
          phone: phone?.trim(),
        );
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  /// Log out
  Future<void> signOut() async {
    await _userDocSubscription?.cancel();
    await _auth.signOut();
    _currentUser = null;
    _firebaseUser = null;
    notifyListeners();
  }

  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An authentication error occurred (${e.code}).';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}
