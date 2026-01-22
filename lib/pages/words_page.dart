import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/words_service.dart';
import 'word_form_page.dart';

class WordsPage extends StatefulWidget {
  const WordsPage({super.key});

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  List<dynamic> _words = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _deleteWord(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Word'),
        content: const Text('Are you sure you want to delete this word?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await WordsService.deleteWord(id);
      if (result['success'] == true) {
        _loadWords();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Word deleted successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] as String? ?? 'Failed to delete word')),
          );
        }
      }
    }
  }

  Widget _buildWordInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.grey600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.grey600,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await WordsService.getAllWords();

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      setState(() {
        _words = data?['data'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['error'] as String? ?? 'Failed to load words';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Row(
        children: [
          Sidebar(currentRoute: '/words'),
          Expanded(
            child: Column(
              children: [
                const app_bar.AppBar(),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Words',
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const WordFormPage(),
                                  ),
                                );
                                if (result == true) {
                                  _loadWords();
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('New Word'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.errorRed),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: AppColors.errorRed),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage!)),
                              ],
                            ),
                          ),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _words.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.menu_book_outlined, size: 64, color: AppColors.grey600),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No words found',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  color: AppColors.grey600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        final crossAxisCount = constraints.maxWidth > 1200
                                            ? 4
                                            : constraints.maxWidth > 900
                                                ? 3
                                                : constraints.maxWidth > 600
                                                    ? 2
                                                    : 1;
                                        return GridView.builder(
                                          padding: const EdgeInsets.all(8),
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 1.2,
                                          ),
                                          itemCount: _words.length,
                                          itemBuilder: (context, index) {
                                            final word = _words[index];
                                            final arabic = word['arabic'] as String? ?? '';
                                            final english = word['english'] as String? ?? '';
                                            final transliteration = word['transliteration'] as String? ?? '';
                                            final categoryObj = word['category'];
                                            final category = categoryObj is Map
                                                ? (categoryObj['name'] as String? ?? categoryObj['slug'] as String? ?? '')
                                                : (categoryObj as String? ?? '');
                                            final level = word['level'] as String? ?? '';
                                            final isActive = word['isActive'] as bool? ?? false;
                                            final id = word['_id'] as String? ?? word['id'] as String? ?? '';
                                            return Card(
                                              elevation: 3,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: InkWell(
                                                onTap: () async {
                                                  final result = await Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => WordFormPage(
                                                        word: word as Map<String, dynamic>,
                                                      ),
                                                    ),
                                                  );
                                                  if (result == true) _loadWords();
                                                },
                                                borderRadius: BorderRadius.circular(16),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(16),
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: isActive
                                                          ? [
                                                              AppColors.primaryGreen.withOpacity(0.05),
                                                              AppColors.darkGreen.withOpacity(0.05),
                                                            ]
                                                          : [
                                                              AppColors.white,
                                                              AppColors.grey100.withOpacity(0.3),
                                                            ],
                                                    ),
                                                  ),
                                                  padding: const EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.primaryGreen.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: Icon(
                                                              Icons.menu_book,
                                                              size: 24,
                                                              color: AppColors.primaryGreen,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  arabic.isNotEmpty ? arabic : english,
                                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 14,
                                                                      ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                  maxLines: 1,
                                                                ),
                                                                if (english.isNotEmpty && arabic.isNotEmpty)
                                                                  Text(
                                                                    english,
                                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                          color: AppColors.grey600,
                                                                          fontSize: 10,
                                                                        ),
                                                                    overflow: TextOverflow.ellipsis,
                                                                    maxLines: 1,
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: isActive
                                                                  ? AppColors.successGreen.withOpacity(0.2)
                                                                  : AppColors.grey600.withOpacity(0.2),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              isActive ? 'Active' : 'Inactive',
                                                              style: TextStyle(
                                                                fontSize: 9,
                                                                fontWeight: FontWeight.bold,
                                                                color: isActive ? AppColors.successGreen : AppColors.grey600,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        height: 1,
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              Colors.transparent,
                                                              AppColors.grey600.withOpacity(0.2),
                                                              Colors.transparent,
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            if (transliteration.isNotEmpty)
                                                              _buildWordInfoRow(Icons.translate, transliteration),
                                                            _buildWordInfoRow(Icons.category, category),
                                                            if (level.isNotEmpty)
                                                              _buildWordInfoRow(Icons.school, level),
                                                          ],
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.edit),
                                                            iconSize: 18,
                                                            onPressed: () async {
                                                              final result = await Navigator.of(context).push(
                                                                MaterialPageRoute(
                                                                  builder: (_) => WordFormPage(
                                                                    word: word as Map<String, dynamic>,
                                                                  ),
                                                                ),
                                                              );
                                                              if (result == true) _loadWords();
                                                            },
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.delete),
                                                            iconSize: 18,
                                                            color: AppColors.errorRed,
                                                            onPressed: () => _deleteWord(id),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
