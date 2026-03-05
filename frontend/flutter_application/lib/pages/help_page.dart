import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'About LexiNote',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'LexiNote helps you upload and study PDF documents by generating quizzes and saving highlights automatically.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _FaqTile(
            question: 'How do I upload a document?',
            answer:
                'Tap the "Upload PDF" button on the Documents tab to pick a PDF from your device.',
          ),
          const _FaqTile(
            question: 'How are quizzes generated?',
            answer:
                'After uploading a document, LexiNote uses AI to extract key concepts and generate questions automatically.',
          ),
          const _FaqTile(
            question: 'How do I save a highlight?',
            answer:
                'Open a document and long-press on any text passage to highlight and save it.',
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: Icon(Icons.email_outlined, color: colorScheme.primary),
            title: const Text('Contact Support'),
            subtitle: const Text('support@lexinote.app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening email client...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(question, style: Theme.of(context).textTheme.bodyLarge),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [Text(answer, style: Theme.of(context).textTheme.bodyMedium)],
      ),
    );
  }
}
