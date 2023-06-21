import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Important note about the exceptions: You may not able to catch the exceptions.
// And it is not likely that the Google will fix this ever. You can only hope
// that it won't happen in the real devices:
// https://github.com/firebase/flutterfire/issues/725#issuecomment-657030135

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool loggedIn = false;
  late final StreamSubscription userAuthSub;
  String lastError = '';

  AuthProvider() {
    userAuthSub = FirebaseAuth.instance.authStateChanges().listen((newUser) {
      _user = newUser;
      notifyListeners();
    }, onError: (e) {
      debugPrint('authStateChanges Error: $e');
    });
  }

  User? get user => _user;

  @override
  void dispose() {
    userAuthSub.cancel();
    super.dispose();
  }

  String? getUid() {
    return _user?.uid;
  }

  bool get isAuthenticated {
    return _user != null;
  }

  Future<void> signOut() async {
    // TODO: stop all stream subscription before signing out to prevent
    // exception caused by unauthenticated operation of listening
    await FirebaseAuth.instance.signOut();
  }

  Future<void> reload() async {
    await FirebaseAuth.instance.currentUser?.reload();
    _user = FirebaseAuth.instance.currentUser;
    notifyListeners();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final account = await GoogleSignIn().signIn();
      final auth = await account?.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: auth?.accessToken, idToken: auth?.idToken);

      return FirebaseAuth.instance.signInWithCredential(credential);
    } on PlatformException catch (e) {
      // don't be alarmed if this does not catch the exception
      // this is one of the never-fixed bugs in Firebase
      // https://stackoverflow.com/questions/56080818/how-to-catch-platformexception-in-flutter-dart
      lastError = e.code;
    } on FirebaseAuthException catch (e) {
      lastError = e.code;
    } catch (e) {
      lastError = e.toString();
    }
    return null;
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
        case 'user-disabled':
        case 'user-not-found':
        case 'wrong-password':
        default:
          lastError = e.code;
      }
    } catch (e) {
      lastError = e.toString();
    }
    return null;
  }

  Future<bool> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
        case 'weak-password':
        case 'invalid-email':
        case 'user-disabled':
        case 'user-not-found':
        case 'wrong-password':
        default:
          lastError = e.code;
      }
    } catch (e) {
      lastError = e.hashCode.toString();
    }
    return false;
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
        case 'missing-android-pkg-name':
        case 'missing-continue-uri':
        case 'missing-ios-bundle-id':
        case 'invalid-continue-uri':
        case 'unauthorized-continue-uri':
        case 'user-not-found':
        default:
          lastError = e.code;
      }
    } catch (e) {
      lastError = e.hashCode.toString();
    }
    return false;
  }
}
