import 'dart:convert';
import '../models/quiz_model.dart';
import 'api_base.dart';

class QuizService extends BaseApiService {
  /// Fetch all quizzes for the current user.
  Future<List<QuizModel>> getQuizzes() async {
    final response = await get('/quiz/');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => QuizModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// AI-generate a quiz for the given document. Returns the created QuizModel.
  Future<QuizModel?> generateQuiz(int documentId) async {
    final response = await post('/quiz/generate/$documentId', {});
    if (response.statusCode == 200) {
      return QuizModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  /// Delete a quiz.
  Future<bool> deleteQuiz(int quizId) async {
    final response = await delete('/quiz/$quizId');
    return response.statusCode == 200;
  }
}
