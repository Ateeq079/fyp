class QuizQuestion {
  final String question;
  final List<String> options; // [A, B, C, D]
  final String correctAnswer; // "A", "B", "C", or "D"

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // Support both list of options and individual option_a/b/c/d keys
    List<String> opts;
    if (json.containsKey('options') && json['options'] is List) {
      opts = List<String>.from(json['options'] as List);
    } else {
      opts = [
        json['option_a'] as String? ?? '',
        json['option_b'] as String? ?? '',
        json['option_c'] as String? ?? '',
        json['option_d'] as String? ?? '',
      ];
    }
    return QuizQuestion(
      question: json['question'] as String,
      options: opts,
      correctAnswer: (json['correct_answer'] as String).toUpperCase(),
    );
  }
}

class QuizModel {
  final int id;
  final String userId;
  final String title;
  final int totalQuestions;
  final int? score;
  final DateTime createdAt;
  final List<QuizQuestion> questions;

  QuizModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.totalQuestions,
    this.score,
    required this.createdAt,
    required this.questions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions_data'] as List<dynamic>;
    return QuizModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      totalQuestions: json['total_questions'] as int,
      score: json['score'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      questions: rawQuestions
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}
