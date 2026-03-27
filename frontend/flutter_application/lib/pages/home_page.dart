import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/vocabulary_service.dart';
import '../models/vocabulary_model.dart';
import '../models/document_model.dart';
import 'login_page.dart';
import 'settings_page.dart';
import 'help_page.dart';
import 'profile_page.dart';
import '../widgets/documents_view.dart';
import '../widgets/quizzes_view.dart';
import '../widgets/vocabulary_view.dart';
import '../widgets/flashcards_view.dart';
import '../services/document_service.dart';
import '../services/auth_service.dart';
import 'pdf_viewer_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _uploading = false;
  final _documentsKey = GlobalKey<DocumentsViewState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Build pages once — avoids recreating DocumentsView on every setState
    _pages = [
      DocumentsView(key: _documentsKey),
      const QuizzesView(),
      const VocabularyView(),
      const FlashcardsView(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // --- Top Navigation Bar ---
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
              showSearch(context: context, delegate: AppSearchDelegate());
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      // --- Navigation Drawer ---
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
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpPage()),
                );
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
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      // --- Main Content Area ---
      body: _pages[_selectedIndex],
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
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
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Dictionary',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Flashcards',
          ),
        ],
      ),
      // --- Upload FAB (Documents tab only) ---
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _uploading ? null : () => _showUploadDialog(context),
              icon: _uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_uploading ? 'Uploading…' : 'Upload PDF'),
            )
          : null,
    );
  }

  Future<void> _showUploadDialog(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    final filename = result.files.single.name;

    setState(() => _uploading = true);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Uploading "$filename"…')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
      ),
    );

    final doc = await DocumentService().uploadDocument(filePath);

    setState(() => _uploading = false);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (doc != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${doc.title}" uploaded successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _documentsKey.currentState?.loadDocuments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class AppSearchDelegate extends SearchDelegate<String> {
  final _docService = DocumentService();
  final _vocabService = VocabularyService();

  @override
  String get searchFieldLabel => 'Search LexiNote…';

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSearchBody(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchBody(context);

  Widget _buildSearchBody(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('Start typing to search…'));
    }

    return FutureBuilder(
      future: Future.wait([
        _docService.getDocuments(),
        _vocabService.getVocabulary(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data![0] as List<DocumentModel>;
        final words = snapshot.data![1] as List<VocabularyModel>;

        final filteredDocs = docs
            .where((d) => d.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
        final filteredWords = words
            .where((w) =>
                w.word.toLowerCase().contains(query.toLowerCase()) ||
                (w.definition?.toLowerCase().contains(query.toLowerCase()) ??
                    false))
            .toList();

        if (filteredDocs.isEmpty && filteredWords.isEmpty) {
          return Center(child: Text('No results found for "$query"'));
        }

        return ListView(
          children: [
            if (filteredDocs.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('DOCUMENTS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              ),
              ...filteredDocs.map((doc) => ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(doc.title),
                    subtitle: Text(doc.fileSizeFormatted),
                    onTap: () {
                      close(context, '');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerPage(document: doc),
                        ),
                      );
                    },
                  )),
            ],
            if (filteredWords.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('DICTIONARY',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              ),
              ...filteredWords.map((word) => ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(word.word),
                    subtitle: Text(word.definition ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      VocabularyView.showWordDetails(context, word);
                    },
                  )),
            ],
          ],
        );
      },
    );
  }
}
