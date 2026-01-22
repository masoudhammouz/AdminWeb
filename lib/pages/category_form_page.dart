import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/categories_service.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class CategoryFormPage extends StatefulWidget {
  final Map<String, dynamic>? category;

  const CategoryFormPage({super.key, this.category});

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _slugController = TextEditingController();
  final _iconController = TextEditingController();
  final _orderController = TextEditingController();
  bool _isLoading = false;
  bool _isActive = true;
  PlatformFile? _selectedImage;
  String? _imageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!['name'] as String? ?? '';
      _nameArController.text = widget.category!['nameAr'] as String? ?? '';
      _slugController.text = widget.category!['slug'] as String? ?? '';
      _iconController.text = widget.category!['icon'] as String? ?? '';
      _orderController.text = (widget.category!['order'] as int? ?? 0).toString();
      _isActive = widget.category!['isActive'] as bool? ?? true;
      // Load existing image URL if available
      _imageUrl = widget.category!['icon'] as String?;
      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        _iconController.text = _imageUrl!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _slugController.dispose();
    _iconController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        // Check if file has bytes (for web) or path (for mobile)
        if (file.bytes == null && file.path == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Could not read file')),
            );
          }
          return;
        }
        setState(() {
          _selectedImage = file;
        });
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploadingImage = true);

    final result = await ApiService.uploadFile(
      ApiConfig.imageUploadUrl,
      _selectedImage!,
      fieldName: 'image',
    );

    setState(() => _isUploadingImage = false);

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      final url = data?['url'] as String? ?? data?['imageUrl'] as String?;
      if (url != null) {
        setState(() {
          _imageUrl = url;
          _iconController.text = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded but URL not received')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Failed to upload image')),
        );
      }
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text.trim(),
      'nameAr': _nameArController.text.trim(),
      'slug': _slugController.text.trim().toLowerCase(),
      'icon': _iconController.text.trim(),
      'order': int.tryParse(_orderController.text) ?? 0,
      'isActive': _isActive,
    };

    final result = widget.category != null
        ? await CategoriesService.updateCategory(
            widget.category!['_id'] as String? ?? widget.category!['id'] as String? ?? '',
            data,
          )
        : await CategoriesService.createCategory(data);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.category != null
                ? 'Category updated successfully'
                : 'Category created successfully'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Failed to save category')),
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
          Sidebar(currentRoute: '/categories'),
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
                                    widget.category != null
                                        ? 'Edit Category'
                                        : 'Create Category',
                                    style: Theme.of(context).textTheme.displayMedium,
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Name (English)',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter category name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _nameArController,
                                    decoration: const InputDecoration(
                                      labelText: 'Name (Arabic)',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter Arabic name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _slugController,
                                    decoration: const InputDecoration(
                                      labelText: 'Slug',
                                      hintText: 'category-slug',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter slug';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Image Upload Section
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Category Icon (PNG)',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 120,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: AppColors.grey600.withOpacity(0.3),
                                                  width: 2,
                                                  style: BorderStyle.solid,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                color: AppColors.grey100,
                                              ),
                                              child: _imageUrl != null && _imageUrl!.isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: Image.network(
                                                        _imageUrl!,
                                                        fit: BoxFit.contain,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Center(
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Icon(Icons.broken_image, color: AppColors.grey600),
                                                                const SizedBox(height: 4),
                                                                Text(
                                                                  'Failed to load image',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: AppColors.grey600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  : _selectedImage != null && _selectedImage!.bytes != null
                                                      ? ClipRRect(
                                                          borderRadius: BorderRadius.circular(10),
                                                          child: Image.memory(
                                                            _selectedImage!.bytes!,
                                                            fit: BoxFit.contain,
                                                          ),
                                                        )
                                                      : Center(
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Icon(Icons.image_outlined, size: 40, color: AppColors.grey600),
                                                              const SizedBox(height: 8),
                                                              Text(
                                                                'No image selected',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: AppColors.grey600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: _isUploadingImage ? null : _pickImage,
                                                icon: _isUploadingImage
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      )
                                                    : const Icon(Icons.upload_file),
                                                label: Text(_isUploadingImage ? 'Uploading...' : 'Upload PNG'),
                                              ),
                                              if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                OutlinedButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _imageUrl = null;
                                                      _selectedImage = null;
                                                      _iconController.clear();
                                                    });
                                                  },
                                                  icon: const Icon(Icons.delete, size: 16),
                                                  label: const Text('Remove'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: AppColors.errorRed,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _iconController,
                                        decoration: const InputDecoration(
                                          labelText: 'Icon URL',
                                          hintText: 'Image URL will appear here after upload',
                                          helperText: 'Or enter image URL manually',
                                        ),
                                        readOnly: _imageUrl != null && _imageUrl!.isNotEmpty && _selectedImage == null,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _orderController,
                                    decoration: const InputDecoration(
                                      labelText: 'Order',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter order';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      return null;
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
                                          onPressed: _isLoading ? null : _saveCategory,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : Text(widget.category != null ? 'Update' : 'Create'),
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
