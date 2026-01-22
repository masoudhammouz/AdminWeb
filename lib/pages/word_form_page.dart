import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/words_service.dart';
import '../services/categories_service.dart';

class WordFormPage extends StatefulWidget {
  final Map<String, dynamic>? word;
  final String? categoryId;

  const WordFormPage({super.key, this.word, this.categoryId});

  @override
  State<WordFormPage> createState() => _WordFormPageState();
}

class _WordFormPageState extends State<WordFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _arabicController = TextEditingController();
  final _englishController = TextEditingController();
  final _transliterationController = TextEditingController();
  final _exampleArController = TextEditingController();
  final _exampleEnController = TextEditingController();
  
  List<dynamic> _categories = [];
  String? _selectedCategoryId;
  String _selectedLevel = 'beginner';
  bool _isActive = true;
  bool _isLoading = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.word != null) {
      _arabicController.text = widget.word!['arabic'] as String? ?? '';
      _englishController.text = widget.word!['english'] as String? ?? '';
      _transliterationController.text = widget.word!['transliteration'] as String? ?? '';
      _exampleArController.text = widget.word!['exampleAr'] as String? ?? '';
      _exampleEnController.text = widget.word!['exampleEn'] as String? ?? '';
      _selectedLevel = widget.word!['level'] as String? ?? 'beginner';
      _isActive = widget.word!['isActive'] as bool? ?? true;
      
      final categoryObj = widget.word!['category'];
      if (categoryObj is Map) {
        _selectedCategoryId = categoryObj['_id'] as String? ?? categoryObj['id'] as String?;
      } else {
        _selectedCategoryId = categoryObj as String?;
      }
    } else if (widget.categoryId != null) {
      // If categoryId is provided (when adding word from category detail page)
      _selectedCategoryId = widget.categoryId;
    }
  }

  @override
  void dispose() {
    _arabicController.dispose();
    _englishController.dispose();
    _transliterationController.dispose();
    _exampleArController.dispose();
    _exampleEnController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final result = await CategoriesService.getAllCategories();
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      final categories = data?['data'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        // Only set default category if not provided via categoryId parameter and not editing existing word
        if (_selectedCategoryId == null && categories.isNotEmpty && widget.word == null && widget.categoryId == null) {
          _selectedCategoryId = categories[0]['_id'] as String? ?? categories[0]['id'] as String?;
        }
      });
    }
  }

  Future<void> _saveWord() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'arabic': _arabicController.text.trim(),
      'english': _englishController.text.trim(),
      'transliteration': _transliterationController.text.trim(),
      'exampleAr': _exampleArController.text.trim(),
      'exampleEn': _exampleEnController.text.trim(),
      'category': _selectedCategoryId,
      'level': _selectedLevel,
      'isActive': _isActive,
    };

    final result = widget.word != null
        ? await WordsService.updateWord(
            widget.word!['_id'] as String? ?? widget.word!['id'] as String? ?? '',
            data,
          )
        : await WordsService.createWord(data);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.word != null
                ? 'Word updated successfully'
                : 'Word created successfully'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Failed to save word')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Sidebar(currentRoute: '/words'),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    widget.word != null ? 'Edit Word' : 'Create Word',
                                    style: Theme.of(context).textTheme.displayMedium,
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _arabicController,
                                    decoration: const InputDecoration(
                                      labelText: 'Arabic',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter Arabic word';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _englishController,
                                    decoration: const InputDecoration(
                                      labelText: 'English',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter English word';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _transliterationController,
                                    decoration: const InputDecoration(
                                      labelText: 'Transliteration',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _exampleArController,
                                    decoration: const InputDecoration(
                                      labelText: 'Example (Arabic)',
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _exampleEnController,
                                    decoration: const InputDecoration(
                                      labelText: 'Example (English)',
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 16),
                                  if (_isLoadingCategories)
                                    const CircularProgressIndicator()
                                  else
                                    DropdownButtonFormField<String>(
                                      value: _selectedCategoryId,
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                      ),
                                      items: _categories.map((cat) {
                                        final id = cat['_id'] as String? ?? cat['id'] as String? ?? '';
                                        final name = cat['name'] as String? ?? '';
                                        return DropdownMenuItem(
                                          value: id,
                                          child: Text(name),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCategoryId = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Please select a category';
                                        }
                                        return null;
                                      },
                                    ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedLevel,
                                    decoration: const InputDecoration(
                                      labelText: 'Level',
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                                      DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                                      DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedLevel = value ?? 'beginner';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  SwitchListTile(
                                    title: const Text('Active'),
                                    value: _isActive,
                                    onChanged: (value) {
                                      setState(() {
                                        _isActive = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _saveWord,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : Text(widget.word != null ? 'Update' : 'Create'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
