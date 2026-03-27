import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../models/document_model.dart';
import '../services/quiz_service.dart';
import '../services/document_service.dart';
import '../pages/quiz_taking_page.dart';
import 'shared_ui.dart';

class QuizzesView extends StatefulWidget {
  const QuizzesView({super.key});

  @override
  State<QuizzesView> createState() => _QuizzesViewState();
}

class _QuizzesViewState extends State<QuizzesView> {
  final _quizService = QuizService();
  final _docService = DocumentService();
  List<QuizModel> _quizzes = [];
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _loading = true);
    final quizzes = await _quizService.getQuizzes();
    if (mounted) setState(() { _quizzes = quizzes; _loading = false; });
  }

  Future<void> _showGenerateDialog() async {
    final docs = await _docService.getDocuments();
    if (!mounted) return;

    if (docs.isEmpty) {
      SharedUI.showSnackBar(context, 'Upload a document first to generate a quiz.', isError: true);
      return;
    }

    DocumentModel? chosen = await showDialog<DocumentModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Quiz'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose a document to generate a quiz from:'),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(docs[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.pop(ctx, docs[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );

    if (chosen == null || !mounted) return;

    setState(() => _generating = true);
    SharedUI.showSnackBar(context, 'Generating quiz for "${chosen.title}"…');

    final quiz = await _quizService.generateQuiz(chosen.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _generating = false);

    if (quiz != null) {
      setState(() => _quizzes.insert(0, quiz));
      SharedUI.showSnackBar(context, 'Quiz "${quiz.title}" ready!');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuizTakingPage(quiz: quiz)),
      );
    } else {
      SharedUI.showSnackBar(context, 'Quiz generation failed.', isError: true);
    }
  }

  Future<void> _deleteQuiz(QuizModel quiz) async {
    final confirmed = await SharedUI.showDeleteConfirmation(
      context: context,
      title: 'Delete Quiz',
      content: 'Delete "${quiz.title}"?',
    );
    if (confirmed == true) {
      final ok = await _quizService.deleteQuiz(quiz.id);
      if (mounted && ok) {
        setState(() => _quizzes.removeWhere((q) => q.id == quiz.id));
        SharedUI.showSnackBar(context, 'Quiz removed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadQuizzes,
        child: _loading
            ? SharedUI.buildLoadingIndicator()
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Quizzes', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            _quizzes.isEmpty
                                ? 'No quizzes yet — generate one!'
                                : '${_quizzes.length} quiz${_quizzes.length == 1 ? '' : 'zes'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_quizzes.isEmpty)
                    SliverFillRemaining(
                      child: SharedUI.buildEmptyState(
                        context,
                        icon: Icons.quiz_outlined,
                        message: 'No quizzes yet. Tap the button to generate one!',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((ctx, i) {
                          final quiz = _quizzes[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Icon(Icons.quiz, color: Theme.of(context).colorScheme.primary),
                              ),
                              title: Text(quiz.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${quiz.totalQuestions} questions'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteQuiz(quiz),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => QuizTakingPage(quiz: quiz)),
                              ),
                            ),
                          );
                        }, childCount: _quizzes.length),
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generating ? null : _showGenerateDialog,
        icon: _generating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome),
        label: Text(_generating ? 'Generating…' : 'Generate Quiz'),
      ),
    );
  }
}
