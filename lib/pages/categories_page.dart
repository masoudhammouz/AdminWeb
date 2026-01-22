import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/categories_service.dart';
import 'category_form_page.dart';
import 'category_detail_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await CategoriesService.getAllCategories();

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      setState(() {
        _categories = data?['data'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['error'] as String? ?? 'Failed to load categories';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleCategory(String id) async {
    final result = await CategoriesService.toggleCategory(id);
    if (result['success'] == true) {
      _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Failed to update category')),
        );
      }
    }
  }

  Future<void> _deleteCategory(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await CategoriesService.deleteCategory(id);
      if (result['success'] == true) {
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] as String? ?? 'Failed to delete category')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.beige,
        body: Row(
          children: [
            Sidebar(currentRoute: '/categories'),
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
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
                                  tooltip: 'Back to Dashboard',
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Categories',
                                  style: Theme.of(context).textTheme.displayMedium,
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CategoryFormPage(),
                                  ),
                                );
                                if (result == true) {
                                  _loadCategories();
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('New Category'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
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
                        ],
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _categories.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.category_outlined, size: 64, color: AppColors.grey600),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No categories found',
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
                                    childAspectRatio: 1.4,
                                  ),
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final category = _categories[index];
                                    final nameEn = category['name'] as String? ?? category['nameEn'] as String? ?? '';
                                    final nameAr = category['nameAr'] as String? ?? '';
                                    final slug = category['slug'] as String? ?? '';
                                    final isActive = category['isActive'] as bool? ?? false;
                                    final order = category['order'] as int? ?? 0;
                                    final id = category['_id'] as String? ?? category['id'] as String? ?? '';
                                    return Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: InkWell(
                                        onTap: () async {
                                          final result = await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => CategoryDetailPage(
                                                category: category as Map<String, dynamic>,
                                              ),
                                            ),
                                          );
                                          if (result == true) _loadCategories();
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
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 48,
                                                    height: 48,
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primaryGreen.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: (category['icon'] as String? ?? '').isNotEmpty
                                                        ? ClipRRect(
                                                            borderRadius: BorderRadius.circular(8),
                                                            child: Image.network(
                                                              category['icon'] as String,
                                                              fit: BoxFit.contain,
                                                              errorBuilder: (context, error, stackTrace) {
                                                                return Icon(
                                                                  Icons.category,
                                                                  size: 28,
                                                                  color: AppColors.primaryGreen,
                                                                );
                                                              },
                                                            ),
                                                          )
                                                        : Icon(
                                                            Icons.category,
                                                            size: 28,
                                                            color: AppColors.primaryGreen,
                                                          ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          nameEn,
                                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 15,
                                                              ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                        if (nameAr.isNotEmpty)
                                                          Text(
                                                            nameAr,
                                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                  color: AppColors.grey600,
                                                                  fontSize: 11,
                                                                ),
                                                            overflow: TextOverflow.ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        isActive ? 'Active' : 'Inactive',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: isActive ? AppColors.successGreen : AppColors.grey600,
                                                        ),
                                                      ),
                                                      Transform.scale(
                                                        scale: 0.8,
                                                        child: Switch(
                                                          value: isActive,
                                                          onChanged: (_) => _toggleCategory(id),
                                                          activeTrackColor: AppColors.primaryGreen,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
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
                                              const SizedBox(height: 12),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    _buildInfoRow(Icons.link, 'Slug', slug),
                                                    _buildInfoRow(Icons.sort, 'Order', order.toString()),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit),
                                                    iconSize: 20,
                                                    onPressed: () async {
                                                      final result = await Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (_) => CategoryFormPage(
                                                            category: category as Map<String, dynamic>,
                                                          ),
                                                        ),
                                                      );
                                                      if (result == true) _loadCategories();
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete),
                                                    iconSize: 20,
                                                    color: AppColors.errorRed,
                                                    onPressed: () => _deleteCategory(id, nameEn),
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
    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.grey600,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
