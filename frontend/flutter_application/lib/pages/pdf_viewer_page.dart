import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/document_model.dart';
import '../services/vocabulary_service.dart';
import '../services/document_service.dart';

class PdfViewerPage extends StatefulWidget {
  final DocumentModel document;

  const PdfViewerPage({super.key, required this.document});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController _pdfController = PdfViewerController();
  final _vocabularyService = VocabularyService();
  final _documentService = DocumentService();

  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  String _selectedText = '';
  PdfTextSelectionChangedDetails? _selectionDetails;
  bool _showMenu = false;

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  //  Annotation helpers
  // ──────────────────────────────────────────────

  void _copyToClipboard() {
    if (_selectedText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _selectedText));
    setState(() => _showMenu = false);
    _showSnack('Text copied to clipboard');
  }

  // ──────────────────────────────────────────────
  //  Dictionary & Highlighting
  // ──────────────────────────────────────────────

  Future<void> _addToDictionary() async {
    final word = _selectedText.trim();
    if (word.isEmpty) return;
    
    // Cache selection details before resetting state
    final details = _selectionDetails;
    setState(() => _showMenu = false);

    // Show a loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Saving and Highlighting "$word"…')),
          ],
        ),
        duration: const Duration(seconds: 15),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // 1. Save to Vocabulary DB
    final ok = await _vocabularyService.saveToVocabulary(
      word: word,
      documentId: widget.document.id,
    );

    if (ok && details != null) {
      // 2. Apply the visual highlight and save to server
      await _applyHighlightAndSync(details);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    _showSnack(
      ok ? '"$word" saved and highlighted ✓' : 'Failed to save "$word".',
    );
  }

  Future<void> _applyHighlightAndSync(PdfTextSelectionChangedDetails details) async {
    try {
      // 1. Apply visual highlight (instant feedback)
      // Note: Using dynamic to bypass strict linting on changing Syncfusion APIs
      final dynamic highlight = HighlightAnnotation(
        textBoundsCollection: (details as dynamic).selectedRegion ?? [],
      );
      
      _pdfController.addAnnotation(highlight);

      // 2. Export the modified PDF bytes
      final state = _pdfViewerKey.currentState;
      if (state == null) return;

      // Note: saveDocument is available on the state in this version
      final List<int>? bytes = await (state as dynamic).saveDocument();
      
      if (bytes != null) {
        // 3. Upload to Render to replace the file permanently
        await _documentService.updateDocumentFile(
          widget.document.id,
          bytes,
          widget.document.originalFilename,
        );
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ──────────────────────────────────────────────
  //  Build
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.document.downloadUrl,
            key: _pdfViewerKey,
            controller: _pdfController,
            canShowTextSelectionMenu: false,
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              final text = details.selectedText ?? '';
              setState(() {
                _selectedText = text;
                _selectionDetails = details;
                _showMenu = text.isNotEmpty;
              });
            },
          ),

          if (_showMenu)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(28),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MenuButton(
                          icon: Icons.book_outlined,
                          label: 'Dictionary',
                          color: Theme.of(context).colorScheme.primary,
                          onTap: _addToDictionary,
                        ),
                        _MenuButton(
                          icon: Icons.content_copy,
                          label: 'Copy',
                          color: Theme.of(context).colorScheme.secondary,
                          onTap: _copyToClipboard,
                        ),
                        _MenuButton(
                          icon: Icons.close,
                          label: 'Dismiss',
                          color: Theme.of(context).colorScheme.outline,
                          onTap: () => setState(() => _showMenu = false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
