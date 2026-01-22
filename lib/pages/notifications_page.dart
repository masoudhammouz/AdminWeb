import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/api_service.dart';
import '../utils/api_config.dart';
import '../services/users_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _formKey = GlobalKey<FormState>();
  final _recipientsController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;
  bool _sendToAll = false;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<String> _selectedUserIds = [];
  bool _isLoadingUsers = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _recipientsController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final result = await UsersService.getAllUsers(limit: 1000);
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        final users = data?['data'] as List<dynamic>? ?? [];
        setState(() {
          _allUsers = users.map((u) => u as Map<String, dynamic>).toList();
          _filteredUsers = _allUsers;
        });
      }
    } catch (e) {
      // Ignore errors
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredUsers = _allUsers.where((user) {
          final name = (user['name'] as String? ?? '').toLowerCase();
          final email = (user['email'] as String? ?? '').toLowerCase();
          return name.contains(lowerQuery) || email.contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    // Save values before clearing
    final title = _titleController.text;
    final body = _bodyController.text;
    final sendToAll = _sendToAll;
    final selectedUserIds = List<String>.from(_selectedUserIds); // Copy the list
    final recipientsText = _recipientsController.text;

    // Clear fields immediately when sending
    _titleController.clear();
    _bodyController.clear();
    _recipientsController.clear();
    _searchController.clear();
    _formKey.currentState!.reset();
    setState(() {
      _sendToAll = false;
      _selectedUserIds = [];
      _filteredUsers = _allUsers;
    });

    setState(() => _isSending = true);

    List<String> userIds = [];

    if (sendToAll) {
      // Send to all users
      userIds = _allUsers
          .map((u) => u['id'] as String? ?? u['_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } else if (selectedUserIds.isNotEmpty) {
      // Use selected users
      userIds = selectedUserIds.where((id) => id.isNotEmpty).toList();
    } else {
      // Parse from email input
      final emails = recipientsText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Convert emails to user IDs
      for (final email in emails) {
        final user = _allUsers.firstWhere(
          (u) => (u['email'] as String? ?? '').toLowerCase() == email.toLowerCase(),
          orElse: () => {},
        );
        if (user.isNotEmpty) {
          final id = user['id'] as String? ?? user['_id'] as String? ?? '';
          if (id.isNotEmpty && !userIds.contains(id)) {
            userIds.add(id);
          }
        }
      }
    }

    if (userIds.isEmpty) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid recipients found')),
        );
      }
      return;
    }

    final result = await ApiService.post(
      ApiConfig.notificationsUrl,
      body: {
        'userIds': userIds,
        'title': title,
        'body': body,
      },
    );

    setState(() => _isSending = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification sent to ${userIds.length} user(s) successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Failed to send notification')),
        );
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
            Sidebar(currentRoute: '/notifications'),
            Expanded(
              child: Column(
                children: [
                  const app_bar.AppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back),
                                      onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
                                      tooltip: 'Back to Dashboard',
                                    ),
                                    const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.notifications_active,
                                      color: AppColors.primaryGreen,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Send Notification',
                                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Send push notifications to users',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              // Recipients Section
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.people,
                                            color: AppColors.primaryGreen,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Recipients',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      // Send to All option
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _sendToAll
                                              ? AppColors.primaryGreen.withOpacity(0.1)
                                              : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _sendToAll
                                                ? AppColors.primaryGreen
                                                : Colors.grey.shade300,
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: _sendToAll,
                                              onChanged: (value) {
                                                setState(() {
                                                  _sendToAll = value ?? false;
                                                  if (_sendToAll) {
                                                    _selectedUserIds = [];
                                                    _recipientsController.clear();
                                                    _searchController.clear();
                                                    _filteredUsers = _allUsers;
                                                  }
                                                });
                                              },
                                              activeColor: AppColors.primaryGreen,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Send to All Users',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (_sendToAll) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${_allUsers.length} users will receive this notification',
                                                      style: TextStyle(
                                                        color: AppColors.primaryGreen,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (_sendToAll)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryGreen,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '${_allUsers.length}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // User Selection (if not sending to all)
                                      if (!_sendToAll) ...[
                                        const Divider(height: 32),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Select Specific Users',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (_selectedUserIds.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryGreen.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: AppColors.primaryGreen,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '${_selectedUserIds.length} selected',
                                                      style: TextStyle(
                                                        color: AppColors.primaryGreen,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Search box
                                        TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            labelText: 'Search users',
                                            hintText: 'Type name or email to search...',
                                            prefixIcon: const Icon(Icons.search),
                                            suffixIcon: _searchController.text.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(Icons.clear),
                                                    onPressed: () {
                                                      _searchController.clear();
                                                      _filterUsers('');
                                                    },
                                                  )
                                                : null,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                          ),
                                          onChanged: _filterUsers,
                                        ),
                                        const SizedBox(height: 16),
                                        // Users list
                                        Container(
                                          height: 250,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: _isLoadingUsers
                                              ? const Center(child: CircularProgressIndicator())
                                              : _filteredUsers.isEmpty
                                                  ? Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            Icons.search_off,
                                                            size: 48,
                                                            color: Colors.grey.shade400,
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            'No users found',
                                                            style: TextStyle(
                                                              color: Colors.grey.shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : ListView.builder(
                                                      itemCount: _filteredUsers.length,
                                                      itemBuilder: (context, index) {
                                                        final user = _filteredUsers[index];
                                                        final id = user['id'] as String? ?? user['_id'] as String? ?? '';
                                                        final name = user['name'] as String? ?? 'Unknown';
                                                        final email = user['email'] as String? ?? '';
                                                        final isSelected = _selectedUserIds.contains(id);
                                                        return InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              if (isSelected) {
                                                                _selectedUserIds.remove(id);
                                                              } else {
                                                                if (!_selectedUserIds.contains(id)) {
                                                                  _selectedUserIds.add(id);
                                                                }
                                                              }
                                                            });
                                                          },
                                                          child: Container(
                                                            color: isSelected
                                                                ? AppColors.primaryGreen.withOpacity(0.1)
                                                                : null,
                                                            child: CheckboxListTile(
                                                              dense: true,
                                                              title: Text(
                                                                name,
                                                                style: TextStyle(
                                                                  fontWeight: isSelected
                                                                      ? FontWeight.w600
                                                                      : FontWeight.normal,
                                                                ),
                                                              ),
                                                              subtitle: Text(
                                                                email,
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors.grey.shade600,
                                                                ),
                                                              ),
                                                              value: isSelected,
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  if (value == true) {
                                                                    if (!_selectedUserIds.contains(id)) {
                                                                      _selectedUserIds.add(id);
                                                                    }
                                                                  } else {
                                                                    _selectedUserIds.remove(id);
                                                                  }
                                                                });
                                                              },
                                                              activeColor: AppColors.primaryGreen,
                                                              controlAffinity: ListTileControlAffinity.leading,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                        ),
                                        if (_selectedUserIds.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  _selectedUserIds.clear();
                                                });
                                              },
                                              icon: const Icon(Icons.clear_all, size: 18),
                                              label: const Text('Clear Selection'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Divider(height: 32),
                                        // Email input alternative
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.alternate_email,
                                              color: AppColors.primaryGreen,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Or Enter Emails Manually',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: _recipientsController,
                                          decoration: InputDecoration(
                                            labelText: 'User Emails (comma-separated)',
                                            hintText: 'email1@example.com, email2@example.com',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            helperText: 'Enter emails separated by commas',
                                            prefixIcon: const Icon(Icons.email),
                                          ),
                                          validator: (value) {
                                            if (!_sendToAll &&
                                                _selectedUserIds.isEmpty &&
                                                (value == null || value.trim().isEmpty)) {
                                              return 'Please select users, enter emails, or send to all';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Message Section
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.message,
                                            color: AppColors.primaryGreen,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Notification Content',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        controller: _titleController,
                                        decoration: InputDecoration(
                                          labelText: 'Title',
                                          hintText: 'Enter notification title',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          prefixIcon: const Icon(Icons.title),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Please enter a title';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _bodyController,
                                        decoration: InputDecoration(
                                          labelText: 'Message Body',
                                          hintText: 'Enter notification message...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          prefixIcon: const Icon(Icons.text_fields),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                        maxLines: 6,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Please enter a message body';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Send Button
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isSending ? null : _sendNotification,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isSending
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text('Sending...'),
                                          ],
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.send, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Send Notification',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
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
    ),
    );
  }
}
