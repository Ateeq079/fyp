import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  
  runApp(const LexiNoteApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Helper to build the combined text theme
TextTheme _buildTextTheme(TextTheme base, Color color) {
  return GoogleFonts.interTextTheme(base).copyWith(
    displayLarge: GoogleFonts.lora(textStyle: base.displayLarge?.copyWith(color: color)),
    displayMedium: GoogleFonts.lora(textStyle: base.displayMedium?.copyWith(color: color)),
    displaySmall: GoogleFonts.lora(textStyle: base.displaySmall?.copyWith(color: color)),
    headlineLarge: GoogleFonts.lora(textStyle: base.headlineLarge?.copyWith(color: color)),
    headlineMedium: GoogleFonts.lora(textStyle: base.headlineMedium?.copyWith(color: color)),
    headlineSmall: GoogleFonts.lora(textStyle: base.headlineSmall?.copyWith(color: color)),
    titleLarge: GoogleFonts.lora(textStyle: base.titleLarge?.copyWith(color: color)),
  );
}

class LexiNoteApp extends StatelessWidget {
  const LexiNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2C3E50); // Deep Blue/Slate
    const secondaryColor = Color(0xFFD68C45); // Warm Gold/Orange
    const backgroundColor = Color(0xFFFAF9F6); // Soft Off-White (Paper)

    final lightBase = ThemeData.light();

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'LexiNote',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: backgroundColor,
          brightness: Brightness.light,
        ),
        textTheme: _buildTextTheme(lightBase.textTheme, primaryColor),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          scrolledUnderElevation: 0, // Keeps it clean without sudden shadows
          centerTitle: false,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Listens to Supabase Auth state changes and routes accordingly.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Start listening to auth state changes soon as app starts
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (!mounted) return;
      if (session != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Shown while checking storage — matches app theme
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_rounded, size: 64),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
