import 'package:flutter/material.dart';
import '../models/quiz_model.dart';

class QuizTakingPage extends StatefulWidget {
  final QuizModel quiz;

  const QuizTakingPage({super.key, required this.quiz});

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage> {
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAnswer; // The letter the user tapped
  bool _answered = false;

  QuizQuestion get _currentQuestion => widget.quiz.questions[_currentIndex];

  void _selectAnswer(String letter) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = letter;
      _answered = true;
      if (letter == _currentQuestion.correctAnswer) {
        _score++;
      }
    });

    // Auto-advance after 1.4 seconds
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_currentIndex < widget.quiz.questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _answered = false;
        });
      } else {
        // Quiz finished — show results
        setState(() {
          _currentIndex = -1; // sentinel for results view
        });
      }
    });
  }

  Color _buttonColor(BuildContext context, String letter) {
    final cs = Theme.of(context).colorScheme;
    if (!_answered) return cs.surface;
    if (letter == _currentQuestion.correctAnswer) return Colors.green.shade400;
    if (letter == _selectedAnswer) return Colors.red.shade400;
    return cs.surface;
  }

  Color _buttonTextColor(BuildContext context, String letter) {
    final cs = Theme.of(context).colorScheme;
    if (!_answered) return cs.onSurface;
    if (letter == _currentQuestion.correctAnswer ||
        letter == _selectedAnswer) {
      return Colors.white;
    }
    return cs.onSurface;
  }

  Widget _buildResultsPage(BuildContext context) {
    final total = widget.quiz.questions.length;
    final pct = total > 0 ? (_score / total * 100).round() : 0;

    Color resultColor;
    String resultMessage;
    IconData resultIcon;

    if (pct >= 80) {
      resultColor = Colors.green.shade500;
      resultMessage = 'Excellent work! 🎉';
      resultIcon = Icons.emoji_events_rounded;
    } else if (pct >= 50) {
      resultColor = Colors.orange.shade500;
      resultMessage = 'Good effort! Keep practicing.';
      resultIcon = Icons.thumb_up_rounded;
    } else {
      resultColor = Colors.red.shade400;
      resultMessage = 'Keep studying — you\'ll get there!';
      resultIcon = Icons.school_rounded;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Results')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(resultIcon, size: 80, color: resultColor),
              const SizedBox(height: 24),
              Text(
                '$_score / $total',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: resultColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$pct% correct',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                resultMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to Quizzes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(BuildContext context) {
    final question = _currentQuestion;
    final total = widget.quiz.questions.length;
    final optionLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / total,
            backgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Question counter
              Text(
                'Question ${_currentIndex + 1} of $total',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              // Question card
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    question.question,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Answer options
              Expanded(
                child: ListView.separated(
                  itemCount: question.options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final letter = i < optionLetters.length ? optionLetters[i] : '?';
                    final text = question.options[i];
                    final bgColor = _buttonColor(context, letter);
                    final textColor = _buttonTextColor(context, letter);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: InkWell(
                        onTap: _answered ? null : () => _selectAnswer(letter),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _answered &&
                                      letter == _currentQuestion.correctAnswer
                                  ? Colors.green.shade400
                                  : _answered && letter == _selectedAnswer
                                      ? Colors.red.shade400
                                      : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                              width: _answered &&
                                      (letter == _currentQuestion.correctAnswer ||
                                          letter == _selectedAnswer)
                                  ? 2
                                  : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: _answered &&
                                        letter ==
                                            _currentQuestion.correctAnswer
                                    ? Colors.green.shade400
                                    : _answered && letter == _selectedAnswer
                                        ? Colors.red.shade400
                                        : Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _answered &&
                                            (letter ==
                                                    _currentQuestion
                                                        .correctAnswer ||
                                                letter == _selectedAnswer)
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  text,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: textColor),
                                ),
                              ),
                              if (_answered &&
                                  letter == _currentQuestion.correctAnswer)
                                const Icon(Icons.check_circle,
                                    color: Colors.white, size: 20),
                              if (_answered &&
                                  letter == _selectedAnswer &&
                                  letter != _currentQuestion.correctAnswer)
                                const Icon(Icons.cancel,
                                    color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == -1) {
      return _buildResultsPage(context);
    }
    return _buildQuestionPage(context);
  }
}
