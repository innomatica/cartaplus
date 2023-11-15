import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartaauth.dart';
import '../../shared/constants.dart';
import '../../shared/flutter_icons.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  //
  // Google Sign In
  //
  Widget _buildSignInWithGoogle(CartaAuth auth) {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        icon: Icon(FlutterIcons.google,
            color: Theme.of(context).colorScheme.tertiary),
        onPressed: () async {
          final result = await auth.signInWithGoogle();
          if (mounted && result == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                'Failed to sign in (${auth.lastError})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ));
          }
        },
        label: const Text('Sign In with Google'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<CartaAuth>();
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              //
              // App Name
              //
              const SizedBox(
                width: 200,
                height: 70,
                child: Center(
                  child: Text(
                    appName,
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.w700,
                      // color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              //
              // Book image
              //
              Image.asset(
                'assets/images/open-book-512.png',
                width: 140.0,
              ),
              const SizedBox(height: 16.0),
              //
              // Google SignIn Button
              //
              _buildSignInWithGoogle(auth),
            ],
          ),
        ),
      ),
    );
  }
}
