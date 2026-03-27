import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

abstract class BaseApiService {
  final String baseUrl = 'http://192.168.1.32:8000/api/v1'; // Matches AuthService
  final _authService = AuthService();

  Future<Map<String, String>> get _headers async {
    final token = await _authService.getToken();
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
