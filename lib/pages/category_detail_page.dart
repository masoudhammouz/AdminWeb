import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/categories_service.dart';
import '../services/words_service.dart';
import 'category_form_page.dart';
import 'word_form_page.dart';

class CategoryDetailPage extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryDetailPage({super.key, required this.category});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  Map<String, dynamic>? _category;
  List<dynamic> _words = [];
  bool _isLoadingCategory = false;
  bool _isLoadingWords = false;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _loadWords();
  }

  Future<void> _refreshCategory() async {
    setState(() => _isLoadingCategory = true);
    final result = await CategoriesService.getAllCategories();
    if (result['success'] == true) {
      final data = result['data'];
      List<dynamic> categories = [];
      if (data is Map) {
        categories = data['data'] as List<dynamic>? ?? [];
      } else if (data is List) {
        categories = data;
      }
      
      final currentId = _category!['_id'] as String? ?? _category!['id'] as String? ?? '';
      final updatedCategory = categories.firstWhere(
        (c) => (c['_id'] as String? ?? c['id'] as String? ?? '') == currentId,
        orElse: () => _category!,
      );
      
      setState(() {
        _category = updatedCategory as Map<String, dynamic>? ?? _category;
        _isLoadingCategory = false;
      });
    } else {
      setState(() => _isLoadingCategory = false);
    }
  }

  Future<void> _loadWords() async {
    setState(() => _isLoadingWords = true);
    final categoryId = _category!['_id'] as String? ?? _category!['id'] as String? ?? '';
    final result = await WordsService.getAllWords(category: categoryId);
    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        if (data is Map) {
          _words = data['data'] as List<dynamic>? ?? [];
        } else if (data is List) {
          _words = data;
        } else {
          _words = [];
        }
        _isLoadingWords = false;
      });
    } else {
      setState(() => _isLoadingWords = false);
    }
  }

  Future<void> _deleteWord(String wordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Word'),
        content: const Text('Are you sure? This will delete the word.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await WordsService.deleteWord(wordId);
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

  @override
  Widget build(BuildContext context) {
    if (_category == null) {
      return Scaffold(
        backgroundColor: AppColors.beige,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final nameEn = _category!['name'] as String? ?? '';
    final nameAr = _category!['nameAr'] as String? ?? '';
    final slug = _category!['slug'] as String? ?? '';
    final order = _category!['order'] as int? ?? 0;
    final isActive = _category!['isActive'] as bool? ?? false;
    final icon = _category!['icon'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: AppColors.beige,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
              const Expanded(child: app_bar.AppBar()),
            ],
          ),
        ),
      ),
      body: Row(
        children: [
          Sidebar(currentRoute: '/categories'),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nameEn,
                                        style: Theme.of(context).textTheme.displayMedium,
                                      ),
                                      if (nameAr.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          nameAr,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                color: AppColors.grey600,
                                              ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Text(
                                        'Slug: $slug | Order: $order | Words: ${_words.length}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: AppColors.grey600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CategoryFormPage(
                                          category: _category!,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _refreshCategory();
                                    }
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Category'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Category'),
                                        content: const Text('Are you sure? This will delete the category and all its words.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      final id = _category!['_id'] as String? ?? _category!['id'] as String? ?? '';
                                      final result = await CategoriesService.deleteCategory(id);
                                      if (result['success'] == true) {
                                        if (mounted) {
                                          Navigator.of(context).pop(true);
                                        }
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(result['error'] as String? ?? 'Failed to delete category')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Category Info Section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category Information',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(Icons.category, color: AppColors.primaryGreen),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Status: ',
                                      style: Theme.of(context).textTheme.bodyMedium,
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
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isActive ? AppColors.successGreen : AppColors.grey600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (icon.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.image, color: AppColors.primaryGreen),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Icon URL: $icon',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.grey600.withOpacity(0.3),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: AppColors.grey100,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        icon,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.broken_image, color: AppColors.grey600),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Failed to load',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.grey600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Words Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Words (${_words.length})',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final categoryId = _category!['_id'] as String? ?? _category!['id'] as String? ?? '';
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => WordFormPage(
                                      categoryId: categoryId,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadWords();
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Word'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingWords)
                          const Center(child: CircularProgressIndicator())
                        else if (_words.isEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.menu_book_outlined, size: 64, color: AppColors.grey600),
                                const SizedBox(height: 16),
                                Text(
                                  'No words found in this category',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppColors.grey600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Click "Add Word" to add words to this category',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.grey600,
                                      ),
                                ),
                              ],
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 1200
                                  ? 4
                                  : constraints.maxWidth > 900
                                      ? 3
                                      : constraints.maxWidth > 600
                                          ? 2
                                          : 1;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
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
                                  final level = word['level'] as String? ?? '';
                                  final isWordActive = word['isActive'] as bool? ?? false;
                                  final id = word['_id'] as String? ?? word['id'] as String? ?? '';
                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                        if (result == true) {
                                          _loadWords();
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
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
                                                    size: 20,
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
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isWordActive
                                                        ? AppColors.successGreen.withOpacity(0.2)
                                                        : AppColors.grey600.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    isWordActive ? 'Active' : 'Inactive',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: isWordActive ? AppColors.successGreen : AppColors.grey600,
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
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (transliteration.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 4),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.translate, size: 12, color: AppColors.grey600),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            transliteration,
                                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                  fontSize: 10,
                                                                  color: AppColors.grey600,
                                                                ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (level.isNotEmpty)
                                                  Row(
                                                    children: [
                                                      Icon(Icons.school, size: 12, color: AppColors.grey600),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        level.toUpperCase(),
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                              fontSize: 10,
                                                              color: AppColors.grey600,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, size: 18),
                                                  color: AppColors.primaryGreen,
                                                  onPressed: () async {
                                                    final result = await Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) => WordFormPage(
                                                          word: word as Map<String, dynamic>,
                                                        ),
                                                      ),
                                                    );
                                                    if (result == true) {
                                                      _loadWords();
                                                    }
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, size: 18),
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
                        const SizedBox(height: 24),
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
