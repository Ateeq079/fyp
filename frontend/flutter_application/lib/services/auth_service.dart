import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Replace with your backend URL.
  // For Android Emulator use 10.0.2.2 usually, but for physical device use your PC's IP.
  // iOS Simulator uses localhost.
  final String baseUrl = 'http://192.168.1.24:8000/api/v1';
  final _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // scopes: ['email'], // explicit scopes if needed
  );

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login/access-token');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        return true;
      } else {
        debugPrint('Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    final url = Uri.parse('$baseUrl/users/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Registration failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  Future<bool> googleLogin() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('Google ID Token is null');
        return false;
      }

      // Send ID token to backend
      final url = Uri.parse('$baseUrl/login/google');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': idToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        return true;
      } else {
        debugPrint('Backend Google Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Google Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _googleSignIn.signOut();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
}
