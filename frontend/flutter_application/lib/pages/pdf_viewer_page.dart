import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/document_model.dart';
import '../services/highlight_service.dart';

class PdfViewerPage extends StatefulWidget {
  final DocumentModel document;

  const PdfViewerPage({super.key, required this.document});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController _pdfController = PdfViewerController();
  final _highlightService = HighlightService();

  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  bool _isDirty = false;
  bool _isSaving = false;
  String _selectedText = '';
  bool _showMenu = false;

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  //  Save annotated PDF back to server
  // ──────────────────────────────────────────────

  Future<void> _saveAnnotatedPdf() async {
    setState(() => _isSaving = true);
    try {
      final List<int> bytes = await _pdfController.saveDocument();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/annotated_${widget.document.id}.pdf',
      );
      await tempFile.writeAsBytes(bytes);

      final result = await _highlightService.replaceDocument(
        widget.document.id,
        tempFile.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result != null
                  ? 'Annotations saved!'
                  : 'Save failed. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (result != null) setState(() => _isDirty = false);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ──────────────────────────────────────────────
  //  Pop guard
  // ──────────────────────────────────────────────

  Future<bool> _confirmPop() async {
    if (!_isDirty) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unsaved Annotations'),
        content: const Text(
          "You have highlights or underlines that haven't been saved yet.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == 'save') await _saveAnnotatedPdf();
    return true;
  }

  // ──────────────────────────────────────────────
  //  Annotation helpers
  // ──────────────────────────────────────────────

  void _applyHighlight() {
    final bounds = _pdfViewerKey.currentState?.getSelectedTextLines();
    if (bounds == null || bounds.isEmpty) return;
    _pdfController.addAnnotation(
      HighlightAnnotation(textBoundsCollection: bounds),
    );
    setState(() {
      _isDirty = true;
      _showMenu = false;
    });
    _showSnack('Text highlighted');
  }

  void _applyUnderline() {
    final bounds = _pdfViewerKey.currentState?.getSelectedTextLines();
    if (bounds == null || bounds.isEmpty) return;
    _pdfController.addAnnotation(
      UnderlineAnnotation(textBoundsCollection: bounds),
    );
    setState(() {
      _isDirty = true;
      _showMenu = false;
    });
    _showSnack('Text underlined');
  }

  Future<void> _addToDictionary() async {
    final word = _selectedText.trim();
    if (word.isEmpty) return;
    setState(() => _showMenu = false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add to Dictionary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Save this word/phrase to your dictionary?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$word"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await _highlightService.saveToVocabulary(
        word: word,
        documentId: widget.document.id,
      );
      if (mounted) {
        _showSnack(
          ok ? '"$word" added to dictionary ✓' : 'Failed to save. Try again.',
        );
      }
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
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final ok = await _confirmPop();
          if (ok && context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.document.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (_isDirty)
              _isSaving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.save_outlined),
                      tooltip: 'Save annotations',
                      onPressed: () async {
                        await _saveAnnotatedPdf();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
          ],
        ),
        body: Stack(
          children: [
            // ── PDF Viewer ────────────────────────────────
            SfPdfViewer.network(
              widget.document.downloadUrl,
              key: _pdfViewerKey,
              controller: _pdfController,
              onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
                final text = details.selectedText ?? '';
                setState(() {
                  _selectedText = text;
                  _showMenu = text.isNotEmpty;
                });
              },
            ),

            // ── Floating context menu ────────────────────
            if (_showMenu)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(28),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
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
                            icon: Icons.highlight,
                            label: 'Highlight',
                            color: Colors.amber.shade700,
                            onTap: _applyHighlight,
                          ),
                          _MenuButton(
                            icon: Icons.format_underlined,
                            label: 'Underline',
                            color: Colors.blue,
                            onTap: _applyUnderline,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Context menu button widget
// ─────────────────────────────────────────────────────────────────────────────

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
