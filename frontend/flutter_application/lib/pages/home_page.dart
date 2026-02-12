import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    _DocumentsView(),
    _QuizzesView(),
    _HighlightsView(),
    _ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('LexiNote'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colorScheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.primary,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to help
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final authService = AuthService();
                await authService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Quizzes',
          ),
          NavigationDestination(
            icon: Icon(Icons.highlight_outlined),
            selectedIcon: Icon(Icons.highlight),
            label: 'Highlights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: Implement upload document
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload PDF'),
            )
          : null,
    );
  }
}

// Documents View
class _DocumentsView extends StatelessWidget {
  const _DocumentsView();

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
              (context, index) => _DocumentCard(index: index),
              childCount: 6, // Placeholder count
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final int index;
  const _DocumentCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Open document
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.picture_as_pdf,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sample Document ${index + 1}',
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '2 days ago',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quizzes View
class _QuizzesView extends StatelessWidget {
  const _QuizzesView();

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
class _HighlightsView extends StatelessWidget {
  const _HighlightsView();

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
class _ProfileView extends StatelessWidget {
  const _ProfileView();

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
        _StatCard(title: 'Documents', value: '12', icon: Icons.description),
        const SizedBox(height: 12),
        _StatCard(title: 'Quizzes Completed', value: '24', icon: Icons.quiz),
        const SizedBox(height: 12),
        _StatCard(title: 'Highlights', value: '56', icon: Icons.highlight),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
