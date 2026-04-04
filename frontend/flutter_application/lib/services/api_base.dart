import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';

abstract class BaseApiService {
  final String baseUrl = AppConstants.apiUrl;

  Future<Map<String, String>> get _headers async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
    );
    _logResponse(endpoint, response);
    return response;
  }

  Future<http.Response> post(String endpoint, dynamic body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
      body: jsonEncode(body),
    );
    _logResponse(endpoint, response);
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
    );
    _logResponse(endpoint, response);
    return response;
  }

  void _logResponse(String endpoint, http.Response response) {
    if (response.statusCode >= 400) {
      debugPrint('API Error [$endpoint]: ${response.statusCode} - ${response.body}');
    }
  }
}
