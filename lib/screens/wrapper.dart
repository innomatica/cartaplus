// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../logic/cartabloc.dart';
import '../logic/cartaauth.dart';
import 'auth/signin.dart';
import 'auth/verifyemail.dart';
import 'home/home.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<CartaAuth>().user;

    return user != null
        ? user.emailVerified
            ? const HomePage()
            : const VerifyEmailPage()
        : const SignInPage();
  }
}
