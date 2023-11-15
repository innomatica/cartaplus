import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Important note about the exceptions: You may not able to catch the exceptions.
// And it is not likely that the Google will fix this ever. You can only hope
// that it won't happen in the real devices:
// https://github.com/firebase/flutterfire/issues/725#issuecomment-657030135

class CartaAuth extends ChangeNotifier {
  User? _user;
  bool loggedIn = false;
  late final StreamSubscription _authListener;
  String lastError = '';

  CartaAuth() {
    _authListener = FirebaseAuth.instance.authStateChanges().listen((newUser) {
      _user = newUser;
      debugPrint('auth listener notified user change: $newUser');
      notifyListeners();
    }, onError: (e) {
      debugPrint('authStateChanges Error: $e');
    });
  }

  User? get user => _user;

  @override
  void dispose() {
    _authListener.cancel();
    super.dispose();
  }

  String? get uid => _user?.uid;
  bool get isAuthenticated => _user != null;

  Future<void> signOut() async {
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
}
