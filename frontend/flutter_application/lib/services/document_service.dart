import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/document_model.dart';
import 'api_base.dart';

class DocumentService extends BaseApiService {
  // ──────────────────────────────────────────────
  //  Upload
  // ──────────────────────────────────────────────

  /// Upload a PDF file. Returns the created [DocumentModel] or null on failure.
  Future<DocumentModel?> uploadDocument(String filePath) async {
    try {
      final token = await (this as dynamic)._authService.getToken();
      final file = File(filePath);
      final filename = file.path.split('/').last;

      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/documents/upload'))
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

      if (response.statusCode == 201) {
        return DocumentModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────
  //  List
  // ──────────────────────────────────────────────

  Future<List<DocumentModel>> getDocuments() async {
    final response = await get('/documents/');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // ──────────────────────────────────────────────
  //  Delete
  // ──────────────────────────────────────────────

  Future<bool> deleteDocument(int documentId) async {
    final response = await delete('/documents/$documentId');
    return response.statusCode == 240 || response.statusCode == 204;
  }
}
