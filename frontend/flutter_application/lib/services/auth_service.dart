import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../pages/login_page.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.session != null) {
        return true;
      }
      return false;
    } on AuthException catch (e) {
      debugPrint('Login Auth error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      // Supabase signUp returns AuthResponse
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      
      // If auto-confirm is enabled in Supabase, session holds the JWT
      // If email confirmation is required, session may be null but user is created.
      // Usually signup succeeds if no exception is thrown
      if (response.user != null) {
        return true;
      }
      return false;
    } on AuthException catch (e) {
      debugPrint('Registration Auth error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  Future<bool> googleLogin() async {
    // We will revisit Google login. For now it triggers Supabase OAuth process.
    try {
      return await _client.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      debugPrint('Google Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<void> handleUnauthorized() async {
    await logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  /// Returns true if there is a valid session
  Future<bool> isLoggedIn() async {
    return _client.auth.currentSession != null;
  }
}
