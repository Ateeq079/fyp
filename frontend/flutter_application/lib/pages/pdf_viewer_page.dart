import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/document_model.dart';
import '../services/vocabulary_service.dart';
import '../services/document_service.dart';
import '../services/pdf_cache_service.dart';

// ──────────────────────────────────────────────
//  Immutable data object for the selection state
// ──────────────────────────────────────────────
class _SelectionState {
  final String text;
  final PdfTextSelectionChangedDetails? details;
  const _SelectionState({this.text = '', this.details});
  bool get hasText => text.isNotEmpty;
}

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

  // Cache state — drives setState only during loading/error, NOT during selection
  String? _localFilePath;
  bool _cacheLoading = true;
  String? _cacheError;

  // ── Selection state: ValueNotifier so SfPdfViewer is NEVER rebuilt on select
  final _selection = ValueNotifier<_SelectionState>(const _SelectionState());

  @override
  void initState() {
    super.initState();
    _loadFromCache();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _selection.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  //  Cache loading
  // ──────────────────────────────────────────────

  Future<void> _loadFromCache() async {
    final path = await PdfCacheService().getLocalPath(widget.document.downloadUrl);
    if (!mounted) return;
    if (path != null) {
      setState(() {
        _localFilePath = path;
        _cacheLoading = false;
      });
    } else {
      setState(() {
        _cacheError = 'Could not load document. Check your connection.';
        _cacheLoading = false;
      });
    }
  }

  // ──────────────────────────────────────────────
  //  Clipboard
  // ──────────────────────────────────────────────

  void _copyToClipboard() {
    final text = _selection.value.text;
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    _selection.value = const _SelectionState(); // hide menu
    _showSnack('Text copied to clipboard');
  }

  // ──────────────────────────────────────────────
  //  Dictionary & Highlighting
  // ──────────────────────────────────────────────

  Future<void> _addToDictionary() async {
    final word = _selection.value.text.trim();
    final details = _selection.value.details;
    if (word.isEmpty) return;

    _selection.value = const _SelectionState(); // hide menu immediately

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

    final ok = await _vocabularyService.saveToVocabulary(
      word: word,
      documentId: widget.document.id,
    );

    if (ok && details != null) {
      await _applyHighlightAndSync(details);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _showSnack(ok ? '"$word" saved and highlighted ✓' : 'Failed to save "$word".');
  }

  Future<void> _applyHighlightAndSync(PdfTextSelectionChangedDetails details) async {
    try {
      final dynamic highlight = HighlightAnnotation(
        textBoundsCollection: (details as dynamic).selectedRegion ?? [],
      );
      _pdfController.addAnnotation(highlight);

      final state = _pdfViewerKey.currentState;
      if (state == null) return;

      final List<int>? bytes = await (state as dynamic).saveDocument();

      if (bytes != null) {
        await _documentService.updateDocumentFile(
          widget.document.id,
          bytes,
          widget.document.originalFilename,
        );

        // Invalidate cache so next open re-downloads the annotated version
        PdfCacheService().invalidate(widget.document.downloadUrl);
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
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Show spinner while downloading to local cache
    if (_cacheLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Loading document…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Show error if download failed
    if (_cacheError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                _cacheError!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _cacheLoading = true;
                    _cacheError = null;
                  });
                  _loadFromCache();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Render PDF from local cached file.
    // RepaintBoundary isolates the PDF render layer from the rest of the tree
    // so the selection menu overlay never triggers a PDF repaint.
    return Stack(
      children: [
        RepaintBoundary(
          child: SfPdfViewer.file(
            File(_localFilePath!),
            key: _pdfViewerKey,
            controller: _pdfController,
            canShowTextSelectionMenu: false,
            canShowScrollHead: false,
            canShowPaginationDialog: false,
            canShowScrollStatus: false,
            pageSpacing: 4.0,
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              final text = details.selectedText ?? '';
              // Only update the notifier when the selection actually changes —
              // this never triggers a setState on the parent widget.
              if (text != _selection.value.text) {
                _selection.value = _SelectionState(text: text, details: details);
              }
            },
          ),
        ),

        // ValueListenableBuilder rebuilds ONLY this small overlay, never SfPdfViewer
        ValueListenableBuilder<_SelectionState>(
          valueListenable: _selection,
          builder: (context, state, _) {
            if (!state.hasText) return const SizedBox.shrink();

            return Positioned(
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
                          onTap: () => _selection.value = const _SelectionState(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
