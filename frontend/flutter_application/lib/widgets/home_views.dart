import 'package:flutter/material.dart';
import 'document_card.dart';
import 'stat_card.dart';

// Documents View
class DocumentsView extends StatelessWidget {
  const DocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Documents',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your uploaded PDFs will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => DocumentCard(
                index: index,
                onTap: () {
                  // TODO: Open document
                },
              ),
              childCount: 6, // Placeholder count
            ),
          ),
        ),
      ],
    );
  }
}

// Quizzes View
class QuizzesView extends StatelessWidget {
  const QuizzesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('Your Quizzes', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Generated quizzes from your documents',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          5,
          (index) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.quiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text('Quiz ${index + 1}'),
              subtitle: Text('From Sample Document ${index + 1}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Open quiz
              },
            ),
          ),
        ),
      ],
    );
  }
}

// Highlights View
class HighlightsView extends StatelessWidget {
  const HighlightsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Saved Highlights',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Important passages from your documents',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          8,
          (index) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Document ${(index % 3) + 1}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is a sample highlighted text that would appear from your PDF documents. '
                    'It could be an important concept or definition.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Page ${index + 1}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Profile View
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.person, size: 48, color: colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'User Name',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'user@example.com',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const StatCard(
          title: 'Documents',
          value: '12',
          icon: Icons.description,
        ),
        const SizedBox(height: 12),
        const StatCard(
          title: 'Quizzes Completed',
          value: '24',
          icon: Icons.quiz,
        ),
        const SizedBox(height: 12),
        const StatCard(title: 'Highlights', value: '56', icon: Icons.highlight),
        const SizedBox(height: 32),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Edit Profile'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Edit profile
          },
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Privacy & Security'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Privacy settings
          },
        ),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Appearance'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Appearance settings
          },
        ),
      ],
    );
  }
}
