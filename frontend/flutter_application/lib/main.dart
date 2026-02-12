import 'package:flutter/material.dart';
import 'pages/signup_page.dart';

void main() {
  runApp(const LexiNoteApp());
}

class LexiNoteApp extends StatelessWidget {
  const LexiNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LexiNote',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
      ),
      home: const SignupPage(),
    );
  }
}
