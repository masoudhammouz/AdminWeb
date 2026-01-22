import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/users_service.dart';
import 'user_detail_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _searchQuery;
  String? _roleFilter;
  bool? _proFilter;
  String? _displayRoleFilter;
  bool? _displayProFilter;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }


  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await UsersService.getAllUsers(
        role: _roleFilter,
        isPro: _proFilter,
        search: _searchQuery,
        page: _currentPage,
        limit: 50, // Increased limit to show more users
      );

      if (result['success'] == true) {
        final responseData = result['data'] as Map<String, dynamic>?;
        
        // Handle different response structures
        List<Map<String, dynamic>> usersList = [];
        int totalPages = 1;
        
        if (responseData != null) {
          // Backend returns: { success: true, data: [...users...], pagination: {...} }
          // ApiService wraps it: { success: true, data: { success: true, data: [...], pagination: {...} } }
          final usersData = responseData['data'];
          final pagination = responseData['pagination'] as Map<String, dynamic>?;
          
          if (usersData != null && usersData is List) {
            // Convert List<dynamic> to List<Map<String, dynamic>> safely
            try {
              usersList = usersData.map((e) {
                if (e is Map<String, dynamic>) {
                  return e;
                } else if (e is Map) {
                  return Map<String, dynamic>.from(e);
                } else {
                  return <String, dynamic>{};
                }
              }).toList();
              totalPages = pagination?['pages'] as int? ?? 1;
            } catch (e) {
              print('Error converting users data: $e');
              usersList = [];
            }
          }
        }
        
        setState(() {
          _users = usersList;
          _totalPages = totalPages;
          _errorMessage = null; // Clear any previous errors
        });
      } else {
        setState(() {
          _errorMessage = result['error'] as String? ?? 'Failed to load users';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await UsersService.deleteUser(id);
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
          _loadUsers();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] as String? ?? 'Failed to delete user')),
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
            Sidebar(currentRoute: '/users'),
            Expanded(
              child: Column(
                children: [
                  const app_bar.AppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
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
                                    'Users',
                                    style: Theme.of(context).textTheme.displayMedium,
                                  ),
                                ],
                              ),
                            const Spacer(),
                            if (_isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Filters
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Search',
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: AppColors.grey100,
                                    ),
                                    onChanged: (value) {
                                      _searchQuery = value.isEmpty ? null : value;
                                    },
                                    onSubmitted: (_) => _loadUsers(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: (_displayRoleFilter != null || _roleFilter != null)
                                          ? AppColors.primaryGreen
                                          : AppColors.grey600,
                                      width: (_displayRoleFilter != null || _roleFilter != null) ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: (_displayRoleFilter != null || _roleFilter != null)
                                        ? AppColors.primaryGreen.withOpacity(0.1)
                                        : AppColors.grey100,
                                  ),
                                  child: DropdownButton<String>(
                                    value: _displayRoleFilter ?? _roleFilter,
                                    hint: const Text('Role'),
                                    underline: const SizedBox(),
                                    isExpanded: false,
                                    items: const [
                                      DropdownMenuItem(value: null, child: Text('All Roles')),
                                      DropdownMenuItem(value: 'student', child: Text('Student')),
                                      DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _displayRoleFilter = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: (_displayProFilter != null || _proFilter != null)
                                          ? AppColors.primaryGreen
                                          : AppColors.grey600,
                                      width: (_displayProFilter != null || _proFilter != null) ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: (_displayProFilter != null || _proFilter != null)
                                        ? AppColors.primaryGreen.withOpacity(0.1)
                                        : AppColors.grey100,
                                  ),
                                  child: DropdownButton<bool?>(
                                    value: _displayProFilter ?? _proFilter,
                                    hint: const Text('Pro Status'),
                                    underline: const SizedBox(),
                                    isExpanded: false,
                                    items: const [
                                      DropdownMenuItem(value: null, child: Text('All')),
                                      DropdownMenuItem(value: true, child: Text('Pro')),
                                      DropdownMenuItem(value: false, child: Text('Free')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _displayProFilter = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _roleFilter = _displayRoleFilter;
                                      _proFilter = _displayProFilter;
                                      _currentPage = 1;
                                    });
                                    _loadUsers();
                                  },
                                  icon: const Icon(Icons.filter_list),
                                  label: const Text('Apply'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                                if (_roleFilter != null || _proFilter != null)
                                  Tooltip(
                                    message: 'Clear filters',
                                    child: IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _roleFilter = null;
                                          _proFilter = null;
                                          _displayRoleFilter = null;
                                          _displayProFilter = null;
                                          _currentPage = 1;
                                        });
                                        _loadUsers();
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Error message
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
                        // Users grid
                        _isLoading
                            ? const SizedBox(
                                height: 400,
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : _users.isEmpty
                                ? SizedBox(
                                    height: 400,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.people_outline,
                                            size: 64,
                                            color: AppColors.grey600,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No users found',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: AppColors.grey600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Calculate number of columns based on screen width
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
                                          childAspectRatio: 1.4, // Wider cards
                                        ),
                                        itemCount: _users.length,
                                        itemBuilder: (context, index) {
                                            final user = _users[index];
                                            final name = user['name'] as String? ?? 'Unknown';
                                            final email = user['email'] as String? ?? '';
                                            final role = user['role'] as String? ?? 'student';
                                            final isPro = user['isPro'] as bool? ?? false;
                                            final points = user['points'] as int? ?? 0;
                                            final streak = user['currentStreak'] as int? ?? 0;
                                            final profilePicture = user['profilePicture'] as String?;

                                        return Card(
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: InkWell(
                                            onTap: () async {
                                              final result = await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => UserDetailPage(user: user),
                                                ),
                                              );
                                              if (result == true) {
                                                _loadUsers();
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: isPro
                                                      ? [
                                                          Colors.amber.withOpacity(0.05),
                                                          Colors.orange.withOpacity(0.05),
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
                                                  // Header with avatar and name
                                                  Row(
                                                    children: [
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          border: Border.all(
                                                            color: isPro ? Colors.amber : AppColors.primaryGreen,
                                                            width: 2.5,
                                                          ),
                                                        ),
                                                        child: _buildProfileAvatar(
                                                          profilePicture: profilePicture,
                                                          name: name,
                                                          size: 48,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              name,
                                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 15,
                                                                  ),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                  Icons.email_outlined,
                                                                  size: 12,
                                                                  color: AppColors.grey600,
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Expanded(
                                                                  child: Text(
                                                                    email,
                                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                          color: AppColors.grey600,
                                                                          fontSize: 11,
                                                                        ),
                                                                    overflow: TextOverflow.ellipsis,
                                                                    maxLines: 1,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (isPro)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: [Colors.amber.shade400, Colors.orange.shade400],
                                                            ),
                                                            borderRadius: BorderRadius.circular(8),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors.amber.withOpacity(0.3),
                                                                blurRadius: 4,
                                                                offset: const Offset(0, 2),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: const [
                                                              Icon(
                                                                Icons.star,
                                                                size: 14,
                                                                color: Colors.white,
                                                              ),
                                                              SizedBox(width: 3),
                                                              Text(
                                                                'Pro',
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  // Divider
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
                                                  // Stats section
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        // Role
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.person_outline,
                                                              size: 16,
                                                              color: AppColors.primaryGreen,
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Expanded(
                                                              child: Text(
                                                                role.toUpperCase(),
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: AppColors.primaryGreen,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        // Points
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.stars_outlined,
                                                              size: 16,
                                                              color: Colors.orange,
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Expanded(
                                                              child: Text(
                                                                '$points Points',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.orange,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        // Streak
                                                        if (streak > 0)
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons.local_fire_department,
                                                                size: 16,
                                                                color: Colors.red,
                                                              ),
                                                              const SizedBox(width: 6),
                                                              Expanded(
                                                                child: Text(
                                                                  '$streak Day Streak',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: Colors.red,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Bottom arrow indicator
                                                  Align(
                                                    alignment: Alignment.centerRight,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primaryGreen.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Icon(
                                                        Icons.arrow_forward_ios,
                                                        size: 12,
                                                        color: AppColors.primaryGreen,
                                                      ),
                                                    ),
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
                        // Pagination
                        if (!_isLoading && _users.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 1
                                      ? () {
                                          setState(() {
                                            _currentPage--;
                                          });
                                          _loadUsers();
                                        }
                                      : null,
                                ),
                                Text('Page $_currentPage of $_totalPages'),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage < _totalPages
                                      ? () {
                                          setState(() {
                                            _currentPage++;
                                          });
                                          _loadUsers();
                                        }
                                      : null,
                                ),
                              ],
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

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar({
    required String? profilePicture,
    required String name,
    required double size,
    required double fontSize,
  }) {
    if (profilePicture == null || profilePicture.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
      );
    }

    // Check if it's a Google image URL
    final isGoogleImage = profilePicture.contains('googleusercontent.com') ||
        profilePicture.contains('google.com') ||
        profilePicture.contains('gstatic.com');

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
      child: ClipOval(
        child: Image.network(
          profilePicture,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              radius: size / 2,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
          // For Google images, try without headers first, then with if needed
          headers: isGoogleImage
              ? {
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                }
              : null,
          cacheWidth: size.toInt(),
          cacheHeight: size.toInt(),
        ),
      ),
    );
  }
}
