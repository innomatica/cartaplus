// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../logic/cartabloc.dart';
import '../logic/authprovider.dart';
import 'auth/signin.dart';
import 'auth/verifyemail.dart';
import 'home/home.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return user != null
        ? user.emailVerified
            ? const HomePage()
            : const VerifyEmailPage()
        : const SignInPage();
  }
}
