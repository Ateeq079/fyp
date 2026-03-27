import 'dart:convert';
import '../models/vocabulary_model.dart';
import 'api_base.dart';

class VocabularyService extends BaseApiService {
  /// Fetch all vocabulary words for the current user.
  Future<List<VocabularyModel>> getVocabulary() async {
    final response = await get('/vocabulary/');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => VocabularyModel.fromJson(json)).toList();
    }
    return [];
  }

  /// Delete a saved vocabulary word.
  Future<bool> deleteVocabulary(int wordId) async {
    final response = await delete('/vocabulary/$wordId');
    return response.statusCode == 204;
  }

  /// Save a selected word/phrase to the user's dictionary.
  Future<bool> saveToVocabulary({
    required String word,
    required int documentId,
    String? contextSentence,
  }) async {
    final response = await post('/vocabulary/', {
      'word': word,
      'document_id': documentId,
      'context_sentence': contextSentence,
    });
    return response.statusCode == 201;
  }
}
