import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/flashcard_service.dart';
import '../services/document_service.dart';
import '../pages/flashcard_review_page.dart';
import 'shared_ui.dart';

class FlashcardsView extends StatefulWidget {
  const FlashcardsView({super.key});

  @override
  State<FlashcardsView> createState() => _FlashcardsViewState();
}

class _FlashcardsViewState extends State<FlashcardsView> {
  final _service = FlashcardService();
  final _docService = DocumentService();
  List<FlashcardModel> _allCards = [];
  List<FlashcardModel> _dueCards = [];
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    setState(() => _loading = true);
    final all = await _service.getFlashcards();
    final due = await _service.getFlashcards(dueOnly: true);
    if (mounted) {
      setState(() {
        _allCards = all;
        _dueCards = due;
        _loading = false;
      });
    }
  }

  Future<void> _showGenerateDialog() async {
    final docs = await _docService.getDocuments();
    if (!mounted) return;

    if (docs.isEmpty) {
      SharedUI.showSnackBar(context, 'Upload a document first.', isError: true);
      return;
    }

    final chosen = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Flashcards'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pick a document to generate flashcards from:'),
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
    SharedUI.showSnackBar(context, 'Generating flashcards for "${chosen.title}"…');

    final cards = await _service.generateFlashcards(chosen.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _generating = false);

    if (cards.isNotEmpty) {
      await _loadFlashcards();
      if (!mounted) return;
      SharedUI.showSnackBar(context, '${cards.length} flashcards generated!');
    } else {
      SharedUI.showSnackBar(context, 'Generation failed.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return SharedUI.buildLoadingIndicator();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadFlashcards,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('Flashcards', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Master your saved vocabulary and highlights.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            // ── Review Banner ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.school, size: 48, color: Theme.of(context).colorScheme.onPrimary),
                  const SizedBox(height: 16),
                  Text(
                    _dueCards.isEmpty ? 'No cards due right now!' : '${_dueCards.length} Cards Due for Review',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _dueCards.isEmpty
                        ? null
                        : () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => FlashcardReviewPage(flashcards: _dueCards)),
                            );
                            _loadFlashcards();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onPrimary,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text('Start Review Session'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text('Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    title: 'Total Cards',
                    value: _allCards.length.toString(),
                    icon: Icons.style,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatBox(
                    title: 'Cards Due',
                    value: _dueCards.length.toString(),
                    icon: Icons.notification_important,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generating ? null : _showGenerateDialog,
        icon: _generating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome),
        label: Text(_generating ? 'Generating…' : 'Generate Flashcards'),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatBox({required this.title, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: effectiveColor),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
