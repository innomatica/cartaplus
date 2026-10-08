import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

const driveScopes = <String>[
  'https://www.googleapis.com/auth/drive.appdata',
  'https://www.googleapis.com/auth/drive.file',
];

/// Google Sign-In supplies short-lived Drive tokens; no Firebase account is
/// required. The Android package and signing certificate must have an OAuth
/// client in the application's Google Cloud project.
class CartaAuth extends ChangeNotifier {
  CartaAuth()
      : _google = GoogleSignIn(
          scopes: driveScopes,
          serverClientId:
              const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID').isEmpty
                  ? null
                  : const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
        ) {
    _listener = _google.onCurrentUserChanged.listen((account) {
      _user = account;
      notifyListeners();
    });
    _google.signInSilently().then((account) {
      _user = account;
      notifyListeners();
    }).catchError((Object error) {
      lastError = error.toString();
      notifyListeners();
    });
  }

  final GoogleSignIn _google;
  late final StreamSubscription<GoogleSignInAccount?> _listener;
  GoogleSignInAccount? _user;
  String lastError = '';

  GoogleSignInAccount? get user => _user;
  String? get uid => _user?.id;
  bool get isAuthenticated => _user != null;

  Future<String> accessToken() async {
    final account = _user;
    if (account == null) throw StateError('Sign in to use Google Drive');
    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null) throw StateError('Google Drive access was not granted');
    return token;
  }

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    lastError = '';
    try {
      final account = await _google.signIn();
      _user = account;
      notifyListeners();
      return account;
    } on PlatformException catch (error) {
      lastError = '${error.code}: ${error.message ?? ''}';
    } catch (error) {
      lastError = error.toString();
    }
    return null;
  }

  Future<void> signOut() async {
    await _google.signOut();
    _user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _listener.cancel();
    super.dispose();
  }
}
