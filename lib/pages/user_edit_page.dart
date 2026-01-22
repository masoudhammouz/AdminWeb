import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/users_service.dart';

class UserEditPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserEditPage({super.key, required this.user});

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pointsController = TextEditingController();
  final _streakController = TextEditingController();
  
  String _selectedRole = 'student';
  String _selectedLevel = 'BEGINNER';
  bool _isPro = false;
  String? _proExpiresAt;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user['name'] as String? ?? '';
    _emailController.text = widget.user['email'] as String? ?? '';
    _pointsController.text = (widget.user['points'] as int? ?? 0).toString();
    _streakController.text = (widget.user['currentStreak'] as int? ?? 0).toString();
    _selectedRole = widget.user['role'] as String? ?? 'student';
    _selectedLevel = widget.user['currentMainLevel'] as String? ?? 'BEGINNER';
    _isPro = widget.user['isPro'] as bool? ?? false;
    final proExpires = widget.user['proExpiresAt'] as String?;
    if (proExpires != null) {
      _proExpiresAt = proExpires.split('T')[0];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pointsController.dispose();
    _streakController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
      'currentMainLevel': _selectedLevel,
      'points': int.tryParse(_pointsController.text) ?? 0,
      'currentStreak': int.tryParse(_streakController.text) ?? 0,
      'isPro': _isPro,
      if (_proExpiresAt != null && _proExpiresAt!.isNotEmpty) 'proExpiresAt': '${_proExpiresAt}T00:00:00.000Z',
    };

    final result = await UsersService.updateUser(
      widget.user['id'] as String? ?? widget.user['_id'] as String? ?? '',
      data,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Failed to update user')),
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
          Sidebar(currentRoute: '/users'),
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
                                    'Edit User',
                                    style: Theme.of(context).textTheme.displayMedium,
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedRole,
                                    decoration: const InputDecoration(
                                      labelText: 'Role',
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'student', child: Text('Student')),
                                      DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedRole = value ?? 'student';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedLevel,
                                    decoration: const InputDecoration(
                                      labelText: 'Level',
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                                      DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
                                      DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedLevel = value ?? 'BEGINNER';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _pointsController,
                                    decoration: const InputDecoration(
                                      labelText: 'Points',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter points';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _streakController,
                                    decoration: const InputDecoration(
                                      labelText: 'Current Streak',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter streak';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  SwitchListTile(
                                    title: const Text('Pro Status'),
                                    value: _isPro,
                                    onChanged: (value) {
                                      setState(() {
                                        _isPro = value;
                                      });
                                    },
                                  ),
                                  if (_isPro) ...[
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: _proExpiresAt,
                                      decoration: const InputDecoration(
                                        labelText: 'Pro Expires At (YYYY-MM-DD)',
                                        hintText: '2025-12-31',
                                      ),
                                      onChanged: (value) {
                                        _proExpiresAt = value;
                                      },
                                    ),
                                  ],
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
                                          onPressed: _isLoading ? null : _saveUser,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Text('Update'),
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
