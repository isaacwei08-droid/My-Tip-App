import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:example_app_2/registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Navigate to the home screen or another part of your app
    } on FirebaseAuthException catch (e) {
      // Handle login errors (e.g., show a snackbar)
      print('Failed to sign in: ${e.message}');
    }
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegistrationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/tipsense_logo.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  semanticLabel: 'TipSense logo',
                ),
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: _goToRegister,
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Don\'t have an account? ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: 'Register',
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
