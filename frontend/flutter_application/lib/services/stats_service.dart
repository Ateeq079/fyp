import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_base.dart';

class UserStats {
  final int totalDocuments;
  final int totalVocabulary;
  final int totalQuizzes;
  final double averageQuizScore;
  final int flashcardsDue;
  final int masteredWords;
  final int studyStreakDays;

  UserStats({
    required this.totalDocuments,
    required this.totalVocabulary,
    required this.totalQuizzes,
    required this.averageQuizScore,
    required this.flashcardsDue,
    required this.masteredWords,
    required this.studyStreakDays,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalDocuments: json['total_documents'] ?? 0,
      totalVocabulary: json['total_vocabulary'] ?? 0,
      totalQuizzes: json['total_quizzes'] ?? 0,
      averageQuizScore: (json['average_quiz_score'] ?? 0.0).toDouble(),
      flashcardsDue: json['flashcards_due'] ?? 0,
      masteredWords: json['mastered_words'] ?? 0,
      studyStreakDays: json['study_streak_days'] ?? 0,
    );
  }
}

class StatsService extends BaseApiService {
  Future<UserStats?> getUserStats() async {
    try {
      final response = await get('/users/me/stats');
      if (response.statusCode == 200) {
        return UserStats.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      return null;
    }
  }
}
