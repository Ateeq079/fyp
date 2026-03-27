import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';
import '../pages/pdf_viewer_page.dart';
import 'document_card.dart';
import 'shared_ui.dart';

class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});

  @override
  State<DocumentsView> createState() => DocumentsViewState();
}

class DocumentsViewState extends State<DocumentsView> {
  final _service = DocumentService();
  List<DocumentModel> _documents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    setState(() => _loading = true);
    final docs = await _service.getDocuments();
    if (mounted) {
      setState(() {
        _documents = docs;
        _loading = false;
      });
    }
  }

  Future<void> _deleteDocument(DocumentModel doc) async {
    final confirmed = await SharedUI.showDeleteConfirmation(
      context: context,
      title: 'Delete Document',
      content: 'Delete "${doc.title}"? This cannot be undone.',
    );

    if (confirmed == true) {
      final ok = await _service.deleteDocument(doc.id);
      if (mounted) {
        if (ok) {
          setState(() => _documents.removeWhere((d) => d.id == doc.id));
          SharedUI.showSnackBar(context, '"${doc.title}" deleted');
        } else {
          SharedUI.showSnackBar(context, 'Failed to delete document', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return SharedUI.buildLoadingIndicator();

    return RefreshIndicator(
      onRefresh: loadDocuments,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Documents', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    _documents.isEmpty
                        ? 'Upload a PDF to get started'
                        : '${_documents.length} document${_documents.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (_documents.isEmpty)
            SliverFillRemaining(
              child: SharedUI.buildEmptyState(
                context,
                icon: Icons.upload_file_outlined,
                message: 'No documents yet. Tap "Upload PDF" to start.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final doc = _documents[index];
                  return DocumentCard(
                    index: index,
                    title: doc.title,
                    subtitle: doc.fileSizeFormatted,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PdfViewerPage(document: doc)),
                      );
                    },
                    onLongPress: () => _deleteDocument(doc),
                  );
                }, childCount: _documents.length),
              ),
            ),
        ],
      ),
    );
  }
}
