import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartaauth.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  late CartaAuth _auth;
  late final Timer _timer;

  @override
  void initState() {
    _auth = context.read<CartaAuth>();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer t) async {
      debugPrint('reload user: $t');
      //
      // This is to workaround another never-fixed flaw in the Firebase
      // https://github.com/flutter/flutter/issues/20390#issuecomment-514411392
      // https://stackoverflow.com/questions/57192651/flutter-how-to-listen-to-the-firebaseuser-is-email-verified-boolean
      //
      try {
        // this can throw exception if the user is deleted
        await _auth.reload();
        final user = _auth.user;
        debugPrint('user:$user ');
        if (user?.emailVerified == true) {
          _timer.cancel();
          if (mounted) {
            Navigator.pushNamed(context, '/');
          }
        }
      } catch (e) {
        debugPrint('exception:$e');
        _timer.cancel();
        // Firebase stream will take care of this
        // Navigator.pushNamed(context, '/');
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Required'),
      ),
      body: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Please check you email',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () async {
                      final user = _auth.user;
                      debugPrint('VerifyEmail.user: $user');
                      await user?.sendEmailVerification();
                    },
                    child: const Text('Resend verification email'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  child: OutlinedButton(
                    onPressed: () async {
                      await _auth.signOut();
                    },
                    child: const Text('Sign Out'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        final result = await FirebaseFunctions.instance
                            .httpsCallable('deleteAuthUser')
                            .call();
                        debugPrint('result: ${result.data}');
                        // _timer.cancel();
                        // if (mounted) {
                        //   Navigator.pushNamed(context, '/');
                        // }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User account deleted'),
                            ),
                          );
                        }
                      } on FirebaseFunctionsException catch (e) {
                        debugPrint(e.message);
                      }
                    },
                    child: const Text('Delete my account'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
