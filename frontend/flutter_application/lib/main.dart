import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignupPage(),
    );
  }
}

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sign Up'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            _InputField(
              label: 'Email',
              icon: Icons.email,
            ),

            const SizedBox(height: 16),

            _InputField(
              label: 'Password',
              icon: Icons.lock,
              obscureText: true,
            ),

            const SizedBox(height: 16),

            _InputField(
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              obscureText: true,
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                // safe placeholder
                debugPrint('Signup button pressed');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool obscureText;

  const _InputField({
    required this.label,
    required this.icon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
