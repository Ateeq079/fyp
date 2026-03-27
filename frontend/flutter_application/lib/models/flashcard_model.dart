class FlashcardModel {
  final int id;
  final int userId;
  final int? highlightId;
  final String question;
  final String answer;
  final DateTime nextReviewDate;
  final int easeFactor;
  final int interval;
  final int repetitions;

  FlashcardModel({
    required this.id,
    required this.userId,
    this.highlightId,
    required this.question,
    required this.answer,
    required this.nextReviewDate,
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      highlightId: json['highlight_id'] as int?,
      question: json['question'] as String,
      answer: json['answer'] as String,
      nextReviewDate: DateTime.parse(json['next_review_date'] as String),
      easeFactor: json['ease_factor'] as int,
      interval: json['interval'] as int,
      repetitions: json['repetitions'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'highlight_id': highlightId,
      'question': question,
      'answer': answer,
      'next_review_date': nextReviewDate.toIso8601String(),
      'ease_factor': easeFactor,
      'interval': interval,
      'repetitions': repetitions,
    };
  }
}
