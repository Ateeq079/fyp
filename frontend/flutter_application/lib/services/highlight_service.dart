import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/document_model.dart';
import 'auth_service.dart';

class HighlightService {
  final String _baseUrl;
  final _storage = const FlutterSecureStorage();

  HighlightService() : _baseUrl = AuthService().baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ──────────────────────────────────────────────
  //  Dictionary (Vocabulary)
  // ──────────────────────────────────────────────

  /// Save a selected word/phrase to the user's dictionary.
  Future<bool> saveToVocabulary({
    required String word,
    required int documentId,
    String? contextSentence,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/vocabulary/'),
        headers: headers,
        body: json.encode({
          'word': word,
          'document_id': documentId,
          'context_sentence': contextSentence,
        }),
      );
      if (response.statusCode == 201) return true;
      if (response.statusCode == 401) {
        await AuthService().handleUnauthorized();
        debugPrint('Save vocab failed: Unauthorized. Logging out.');
        return false;
      }
      debugPrint(
        'Save vocab failed [${response.statusCode}]: ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('Save vocab error: $e');
      return false;
    }
  }

  /// Fetch all vocabulary words for the current user.
  Future<List<Map<String, dynamic>>> getVocabulary() async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('$_baseUrl/vocabulary/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401) {
        await AuthService().handleUnauthorized();
        debugPrint('Get vocab failed: Unauthorized. Logging out.');
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Get vocab error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────
  //  Replace annotated PDF
  // ──────────────────────────────────────────────

  /// Re-upload an annotated PDF to replace the original on the server.
  Future<DocumentModel?> replaceDocument(
    int documentId,
    String filePath,
  ) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final filename = File(filePath).path.split('/').last;

      final request =
          http.MultipartRequest(
              'PUT',
              Uri.parse('$_baseUrl/documents/$documentId/file'),
            )
            ..headers['Authorization'] = 'Bearer $token'
            ..files.add(
              await http.MultipartFile.fromPath(
                'file',
                filePath,
                filename: filename,
              ),
            );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        return DocumentModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        await AuthService().handleUnauthorized();
        debugPrint('Replace doc failed: Unauthorized. Logging out.');
        return null;
      }
      debugPrint(
        'Replace doc failed [${response.statusCode}]: ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('Replace doc error: $e');
      return null;
    }
  }
}
