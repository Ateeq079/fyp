import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vocabulary_model.dart';
import '../models/document_model.dart';
import '../services/vocabulary_service.dart';
import '../services/document_service.dart';
import 'shared_ui.dart';

class VocabularyView extends StatefulWidget {
  const VocabularyView({super.key});

  @override
  State<VocabularyView> createState() => _VocabularyViewState();

  static void showWordDetails(BuildContext context, VocabularyModel word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Word
                  Text(
                    word.word,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  // Blue Definition Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Definition',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          word.definition ?? 'No definition available.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Links section
                  Text(
                    'Learn More',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  // Display multiple links if available
                  if (word.relatedLinks != null && word.relatedLinks!.isNotEmpty)
                    ...word.relatedLinks!.map((link) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildLinkTile(
                            context,
                            title: link.title,
                            subtitle: link.url,
                          ),
                        ))
                  else if (word.sourceName != null && word.sourceUrl != null && word.sourceName!.isNotEmpty && word.sourceUrl!.isNotEmpty)
                    _buildLinkTile(
                      context,
                      title: word.sourceName!,
                      subtitle: word.sourceUrl!,
                    )
                  else
                    _buildLinkTile(
                      context,
                      title: 'Wikipedia',
                      subtitle: 'https://en.wikipedia.org/wiki/${Uri.encodeComponent(word.word)}',
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildLinkTile(BuildContext context, {required String title, required String subtitle}) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(subtitle);
        try {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched) throw Exception('Launch returned false');
        } catch (e) {
          if (context.mounted) {
            SharedUI.showSnackBar(context, 'Could not launch link', isError: true);
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.normal,
                    fontSize: 22,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VocabularyViewState extends State<VocabularyView> {
  final _service = VocabularyService();
  final _docService = DocumentService();
  
  List<VocabularyModel> _words = [];
  Map<int, String> _documentTitles = {};
  Map<int, List<VocabularyModel>> _groupedWords = {};
  
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadVocabulary();
  }

  Future<void> loadVocabulary() async {
    setState(() => _loading = true);
    
    final results = await Future.wait([
      _service.getVocabulary(),
      _docService.getDocuments(),
    ]);

    final words = results[0] as List<VocabularyModel>;
    final docs = results[1] as List<DocumentModel>;

    if (mounted) {
      final docMap = {for (var d in docs) d.id: d.title};
      final grouped = <int, List<VocabularyModel>>{};
      for (var w in words) {
        grouped.putIfAbsent(w.documentId, () => []).add(w);
      }

      setState(() {
        _words = words;
        _documentTitles = docMap;
        _groupedWords = grouped;
        _loading = false;
      });
    }
  }

  Future<void> _deleteWord(VocabularyModel word) async {
    final confirmed = await SharedUI.showDeleteConfirmation(
      context: context,
      title: 'Remove Word',
      content: 'Remove "${word.word}" from your dictionary?',
      confirmLabel: 'Remove',
    );

    if (confirmed == true) {
      final ok = await _service.deleteVocabulary(word.id);
      if (mounted && ok) {
        setState(() {
          _words.removeWhere((w) => w.id == word.id);
          _groupedWords[word.documentId]?.removeWhere((w) => w.id == word.id);
          if (_groupedWords[word.documentId]?.isEmpty ?? false) {
            _groupedWords.remove(word.documentId);
          }
        });
        SharedUI.showSnackBar(context, '"${word.word}" removed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return SharedUI.buildLoadingIndicator();

    return RefreshIndicator(
      onRefresh: loadVocabulary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dictionary', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    _words.isEmpty
                        ? 'No words saved yet'
                        : '${_words.length} saved word${_words.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_words.isEmpty)
            SliverFillRemaining(
              child: SharedUI.buildEmptyState(
                context,
                icon: Icons.menu_book_outlined,
                message: 'Your dictionary is empty. Highlight words in PDFs to save them.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final docId = _groupedWords.keys.elementAt(index);
                  final docTitle = _documentTitles[docId] ?? 'Document #$docId';
                  final wordsInDoc = _groupedWords[docId]!;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(docTitle),
                        children: wordsInDoc.map((word) {
                          return ListTile(
                            onTap: () => VocabularyView.showWordDetails(context, word),
                            title: Text(
                              word.word,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (word.definition != null && word.definition!.isNotEmpty)
                                  Text(word.definition!, maxLines: 2, overflow: TextOverflow.ellipsis),
                                if (word.contextSentence != null && word.contextSentence!.isNotEmpty)
                                  Text('"${word.contextSentence!}"', 
                                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteWord(word),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }, childCount: _groupedWords.length),
              ),
            ),
        ],
      ),
    );
  }
}
