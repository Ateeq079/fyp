import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';
import 'api_base.dart';

class DocumentService extends BaseApiService {
  // ──────────────────────────────────────────────
  //  Upload
  // ──────────────────────────────────────────────

  /// Upload a PDF file. Returns the created [DocumentModel] or null on failure.
  Future<DocumentModel?> uploadDocument(String filePath) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      
      if (token == null) {
        debugPrint('Upload error: No active session/token found');
        return null;
      }

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

  // ──────────────────────────────────────────────
  //  Update File (Annotations)
  // ──────────────────────────────────────────────

  /// Replace document file with an annotated one.
  Future<bool> updateDocumentFile(int documentId, List<int> bytes, String filename) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      if (token == null) return false;

      final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/documents/$documentId/file'))
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: filename,
          ),
        );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        debugPrint('File update successful for doc: $documentId');
        return true;
      } else {
         debugPrint('File update failed with status: ${response.statusCode}');
         return false;
      }
    } catch (e) {
      debugPrint('Update file error: $e');
      return false;
    }
  }
}
