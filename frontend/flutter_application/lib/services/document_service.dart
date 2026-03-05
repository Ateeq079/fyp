import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/document_model.dart';
import 'auth_service.dart';

class DocumentService {
  final String _baseUrl;
  final _storage = const FlutterSecureStorage();

  DocumentService() : _baseUrl = AuthService().baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {'Authorization': 'Bearer $token'};
  }

  // ──────────────────────────────────────────────
  //  Upload
  // ──────────────────────────────────────────────

  /// Upload a PDF file. Returns the created [DocumentModel] or null on failure.
  Future<DocumentModel?> uploadDocument(String filePath) async {
    try {
      final headers = await _authHeaders();
      final file = File(filePath);
      final filename = file.path.split('/').last;

      final request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/documents/upload'))
            ..headers.addAll(headers)
            ..files.add(
              await http.MultipartFile.fromPath(
                'file',
                filePath,
                filename: filename,
              ),
            );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        return DocumentModel.fromJson(json.decode(response.body));
      } else {
        debugPrint('Upload failed [${response.statusCode}]: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────
  //  List
  // ──────────────────────────────────────────────

  /// Fetch all documents for the current user.
  Future<List<DocumentModel>> getDocuments() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/documents/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('List documents failed [${response.statusCode}]');
        return [];
      }
    } catch (e) {
      debugPrint('List documents error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────
  //  Delete
  // ──────────────────────────────────────────────

  /// Delete a document by ID. Returns true on success.
  Future<bool> deleteDocument(int documentId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/documents/$documentId'),
        headers: headers,
      );
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete document error: $e');
      return false;
    }
  }
}
