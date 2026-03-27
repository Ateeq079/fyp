import 'dart:math';
import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/flashcard_service.dart';

class FlashcardReviewPage extends StatefulWidget {
  final List<FlashcardModel> flashcards;

  const FlashcardReviewPage({super.key, required this.flashcards});

  @override
  State<FlashcardReviewPage> createState() => _FlashcardReviewPageState();
}

class _FlashcardReviewPageState extends State<FlashcardReviewPage>
    with SingleTickerProviderStateMixin {
  late List<FlashcardModel> _cardsToReview;
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _animation;
  final FlashcardService _flashcardService = FlashcardService();

  @override
  void initState() {
    super.initState();
    _cardsToReview = List.from(widget.flashcards);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  Future<void> _submitScore(int score) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final currentCard = _cardsToReview[_currentIndex];
    
    try {
      await _flashcardService.reviewFlashcard(
        currentCard.id,
        score,
      );

      if (mounted) {
        // Move to next card
        setState(() {
          _isFlipped = false;
          _animationController.value = 0; // reset animation instantly

          if (_currentIndex < _cardsToReview.length - 1) {
            _currentIndex++;
          } else {
            // Finished stack
            _cardsToReview.clear();
          }
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        } else {
          errorMsg = 'Failed to submit review. Tap a score to retry.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildCardSide(String text, bool isFront) {
    return Container(
      width: double.infinity,
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isFront
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isFront ? 'Question' : 'Answer',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isFront
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                text,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isFront
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cardsToReview.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Session')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'You\'re all caught up!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final currentCard = _cardsToReview[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Review (${_currentIndex + 1}/${_cardsToReview.length})'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _flipCard,
                  child: Center(
                    child: Transform(
                      alignment: FractionalOffset.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(pi * _animation.value),
                      child: _animation.value <= 0.5
                          ? _buildCardSide(currentCard.question, true)
                          : Transform(
                              alignment: FractionalOffset.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: _buildCardSide(currentCard.answer, false),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (!_isFlipped)
                Text(
                  'Tap the card to see the answer',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Column(
                  children: [
                    Text(
                      'How well did you know this?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ReviewButton(
                          label: 'Hard\n(Again)',
                          color: Colors.red.shade400,
                          onTap: _isSubmitting ? null : () => _submitScore(1),
                        ),
                        _ReviewButton(
                          label: 'Good',
                          color: Colors.orange.shade400,
                          onTap: _isSubmitting ? null : () => _submitScore(3),
                        ),
                        _ReviewButton(
                          label: 'Easy',
                          color: Colors.green.shade500,
                          onTap: _isSubmitting ? null : () => _submitScore(5),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ReviewButton({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
