import 'dart:convert';
import '../models/flashcard_model.dart';
import 'api_base.dart';

class FlashcardService extends BaseApiService {
  /// Generate flashcards for a specific document. Returns the created cards.
  Future<List<FlashcardModel>> generateFlashcards(int documentId) async {
    final response = await post('/flashcards/generate/$documentId', {});
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => FlashcardModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Fetch all flashcards for the current user.
  Future<List<FlashcardModel>> getFlashcards({bool dueOnly = false}) async {
    final endpoint = dueOnly ? '/flashcards/?due_only=true' : '/flashcards/';
    final response = await get(endpoint);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => FlashcardModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Review a flashcard using the SuperMemo-2 algorithm.
  Future<FlashcardModel> reviewFlashcard(int flashcardId, int quality) async {
    final response = await post('/flashcards/$flashcardId/review', {'quality': quality});
    if (response.statusCode == 200) {
      return FlashcardModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to review flashcard');
  }
}
