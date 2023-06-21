import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/authprovider.dart';
import '../../shared/constants.dart';
import '../../shared/flutter_icons.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _pswController = TextEditingController();
  bool _signInWithEmail = false;
  bool _createAccount = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _pswController.dispose();
    super.dispose();
  }

  //
  // Google Sign In
  //
  Widget _buildSignInWithGoogle(AuthProvider auth) {
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

  //
  // Email Password Sign In
  //
  Widget _buildSignInWithEmail(AuthProvider auth) {
    return Column(
      children: [
        // Email and Password Form without validation
        _signInWithEmail
            ? Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      isDense: true,
                      icon: Icon(Icons.email_rounded),
                      label: Text('email'),
                    ),
                  ),
                  TextFormField(
                    controller: _pswController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: _obscurePassword
                            ? const Icon(Icons.visibility_rounded)
                            : const Icon(Icons.visibility_off_rounded),
                        onPressed: () {
                          _obscurePassword = !_obscurePassword;
                          setState(() {});
                        },
                      ),
                      isDense: true,
                      icon: const Icon(Icons.password_rounded),
                      label: const Text('password'),
                    ),
                  ),
                  const SizedBox(height: 22.0),
                ],
              )
            : const SizedBox(height: 0),
        // Sign In with Email and Password
        SizedBox(
          width: 200,
          child: ElevatedButton(
            onPressed: () async {
              if (_signInWithEmail == false) {
                _signInWithEmail = true;
                _createAccount = false;
                setState(() {});
              } else if (_emailController.text.isNotEmpty &&
                  _pswController.text.isNotEmpty) {
                FocusManager.instance.primaryFocus?.unfocus();
                final result = await auth.signInWithEmailAndPassword(
                    email: _emailController.text,
                    password: _pswController.text);
                if (mounted && result == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      'Failed to sign in (${auth.lastError})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ));
                }
              }
            },
            child: Text(_signInWithEmail ? 'Log in' : 'Sign in with email'),
          ),
        ),
      ],
    );
  }

  //
  // Creat a New Account
  //
  Widget _buildCreateAccount(AuthProvider auth) {
    return Column(
      children: [
        // Email and Password Form with validation
        _createAccount
            ? Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        isDense: true,
                        icon: Icon(Icons.email_rounded),
                        label: Text('email'),
                        // hintText: 'jane.doe@email.com',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'valid email addres is required';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _pswController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: _obscurePassword
                              ? const Icon(Icons.visibility_rounded)
                              : const Icon(Icons.visibility_off_rounded),
                          onPressed: () {
                            _obscurePassword = !_obscurePassword;
                            setState(() {});
                          },
                        ),
                        isDense: true,
                        icon: const Icon(Icons.password_rounded),
                        label: const Text('password'),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.length < 8) {
                          return 'password should be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22.0),
                  ],
                ),
              )
            : const SizedBox(height: 0),
        // Create a New Account
        SizedBox(
          width: 200,
          child: OutlinedButton(
            onPressed: () async {
              if (_createAccount == false) {
                _createAccount = true;
                _signInWithEmail = false;
                setState(() {});
              } else {
                if (_formKey.currentState!.validate()) {
                  final result = await auth.createUserWithEmailAndPassword(
                      email: _emailController.text,
                      password: _pswController.text);
                  if (mounted && result == false) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text('Failed to create account (${auth.lastError})'),
                    ));
                  }
                }
              }
            },
            child: Text(
              _createAccount ? 'Create' : 'Create a new account',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  //
  // Reset Password
  //
  Widget _buildPasswordReset(AuthProvider auth) {
    return SizedBox(
      width: 200,
      child: TextButton(
        onPressed: () {
          String? email;

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                    // color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Email field
                    TextField(
                      onChanged: (value) => email = value,
                      decoration: const InputDecoration(
                        isDense: true,
                        icon: Icon(Icons.email_rounded),
                        label: Text('email'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Send email button
                    ElevatedButton(
                      onPressed: () async {
                        if (email != null && email!.isNotEmpty) {
                          FocusManager.instance.primaryFocus?.unfocus();
                          final result =
                              await auth.sendPasswordResetEmail(email: email!);

                          if (mounted && result == false) {
                            Navigator.of(context).pop(
                                'Failed to send email (${auth.lastError})');
                          }
                        }
                      },
                      child: const Text('Send password reset email'),
                    ),
                  ],
                ),
              );
            },
          ).then((value) {
            if (value != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$value'),
              ));
            }
          });
        },
        child: Text(
          'Forgot password?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              //
              // Book image
              //
              Stack(
                // mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(
                    width: 200,
                    height: 70,
                    child: Center(
                      child: Text(
                        appName,
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w600,
                          // color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Transform.rotate(
                      angle: 0.4,
                      child: Image.asset(
                        'assets/images/open-book-512.png',
                        width: 30.0,
                      ),
                    ),
                  ),
                ],
              ),
              //
              // Sign In
              //
              Text(
                'Sign in to proceed',
                style: TextStyle(
                  // fontSize: 30.0,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 18.0),
              //
              // Sign In with Google
              //
              _buildSignInWithGoogle(auth),
              const SizedBox(height: 8.0),
              //
              // Sign in with Email and Password
              //
              _buildSignInWithEmail(auth),
              const SizedBox(height: 8.0),
              //
              // Create account with Email and Password
              //
              _buildCreateAccount(auth),
              const SizedBox(height: 8.0),
              //
              // Password Reset Button
              //
              _buildPasswordReset(auth),
            ],
          ),
        ),
      ),
    );
  }
}
