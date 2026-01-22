import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/users_service.dart';

class UserDetailPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailPage({super.key, required this.user});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSaving = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pointsController = TextEditingController();
  final _streakController = TextEditingController();
  final _longestStreakController = TextEditingController();
  final _dobController = TextEditingController();
  final _nativeLangController = TextEditingController();
  final _learningGoalController = TextEditingController();
  final _proExpiresController = TextEditingController();

  String _selectedRole = 'student';
  String _selectedLevel = 'BEGINNER';
  String? _selectedGender;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = widget.user;
    _nameController.text = user['name'] as String? ?? '';
    _emailController.text = user['email'] as String? ?? '';
    _pointsController.text = (user['points'] as int? ?? 0).toString();
    _streakController.text = (user['currentStreak'] as int? ?? 0).toString();
    _longestStreakController.text = (user['longestStreak'] as int? ?? 0).toString();
    _selectedRole = user['role'] as String? ?? 'student';
    _selectedLevel = user['currentMainLevel'] as String? ?? 'BEGINNER';
    final genderValue = user['gender'] as String?;
    // Normalize gender value to match dropdown options
    if (genderValue == null || genderValue.isEmpty || genderValue == 'None' || genderValue == 'none') {
      _selectedGender = null;
    } else if (['male', 'female', 'other'].contains(genderValue.toLowerCase())) {
      _selectedGender = genderValue.toLowerCase();
    } else {
      _selectedGender = null; // Default to null if unknown value
    }
    _isPro = user['isPro'] as bool? ?? false;

    final dob = user['dateOfBirth'] as String?;
    if (dob != null) {
      try {
        final date = DateTime.parse(dob);
        _dobController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } catch (e) {
        _dobController.text = dob.split('T')[0];
      }
    }

    _nativeLangController.text = user['nativeLanguage'] as String? ?? '';
    _learningGoalController.text = user['learningGoal'] as String? ?? '';

    final proExpires = user['proExpiresAt'] as String?;
    if (proExpires != null) {
      _proExpiresController.text = proExpires.split('T')[0];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pointsController.dispose();
    _streakController.dispose();
    _longestStreakController.dispose();
    _dobController.dispose();
    _nativeLangController.dispose();
    _learningGoalController.dispose();
    _proExpiresController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final id = widget.user['id'] as String? ?? widget.user['_id'] as String? ?? '';
      final result = await UsersService.getUserById(id);
      if (result['success'] == true) {
        final userData = result['data'] as Map<String, dynamic>? ?? result;
        setState(() {
          widget.user.clear();
          widget.user.addAll(userData);
          _loadUserData();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUser() async {
    setState(() {
      _isSaving = true;
    });

    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
      'currentMainLevel': _selectedLevel,
      'points': int.tryParse(_pointsController.text) ?? 0,
      'currentStreak': int.tryParse(_streakController.text) ?? 0,
      'longestStreak': int.tryParse(_longestStreakController.text) ?? 0,
      'isPro': _isPro,
      if (_selectedGender != null) 'gender': _selectedGender,
      if (_dobController.text.isNotEmpty) 'dateOfBirth': '${_dobController.text}T00:00:00.000Z',
      if (_nativeLangController.text.isNotEmpty) 'nativeLanguage': _nativeLangController.text.trim(),
      if (_learningGoalController.text.isNotEmpty) 'learningGoal': _learningGoalController.text.trim(),
      if (_isPro && _proExpiresController.text.isNotEmpty) 'proExpiresAt': '${_proExpiresController.text}T00:00:00.000Z',
    };

    final id = widget.user['id'] as String? ?? widget.user['_id'] as String? ?? '';
    final result = await UsersService.updateUser(id, data);

    setState(() {
      _isSaving = false;
    });

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        setState(() {
          _isEditing = false;
        });
        _loadUser();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] as String? ?? 'Failed to update user'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.split('T')[0];
    }
  }

  String? _calculateAge(String? dobStr) {
    if (dobStr == null) return null;
    try {
      final dob = DateTime.parse(dobStr);
      final now = DateTime.now();
      final age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        return (age - 1).toString();
      }
      return age.toString();
    } catch (e) {
      return null;
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard!'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final id = user['id'] as String? ?? user['_id'] as String? ?? '';
    final name = user['name'] as String? ?? 'Unknown';
    final email = user['email'] as String? ?? '';
    final profilePicture = user['profilePicture'] as String?;
    final isPro = user['isPro'] as bool? ?? false;
    final createdAt = user['createdAt'] as String?;
    final lastActivity = user['lastActivityDate'] as String?;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Row(
        children: [
          Sidebar(currentRoute: '/users'),
          Expanded(
            child: Column(
              children: [
                const app_bar.AppBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () => Navigator.of(context).pop(true),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'User Details',
                                      style: Theme.of(context).textTheme.displayMedium,
                                    ),
                                  ),
                                  if (!_isEditing)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = true;
                                        });
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                    )
                                  else
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        OutlinedButton(
                                          onPressed: _isSaving
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _isEditing = false;
                                                  });
                                                  _loadUserData();
                                                },
                                          child: const Text('Cancel'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: _isSaving ? null : _saveUser,
                                          child: _isSaving
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Text('Save'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Profile Card
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Row(
                                    children: [
                                      _buildProfileAvatar(
                                        profilePicture: profilePicture,
                                        name: name,
                                        size: 96,
                                        fontSize: 36,
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: Theme.of(context).textTheme.displaySmall,
                                                  ),
                                                ),
                                                if (isPro)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        Icon(
                                                          Icons.star,
                                                          size: 20,
                                                          color: Colors.amber,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Pro',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.amber,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () => _copyToClipboard(email, 'Email'),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.email, size: 16, color: AppColors.grey600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    email,
                                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                          color: AppColors.grey600,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.copy, size: 14, color: AppColors.grey600),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () => _copyToClipboard(id, 'ID'),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.fingerprint, size: 16, color: AppColors.grey600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'ID: ${id.substring(0, 8)}...',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: AppColors.grey600,
                                                          fontFamily: 'monospace',
                                                        ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.copy, size: 14, color: AppColors.grey600),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Information Sections
                              _buildSection(
                                'Basic Information',
                                Icons.person,
                                [
                                  _buildInfoField('Name', _nameController, Icons.person, enabled: _isEditing),
                                  _buildInfoField('Email', _emailController, Icons.email, enabled: _isEditing),
                                  _buildDropdownField(
                                    'Role',
                                    _selectedRole,
                                    ['student', 'teacher', 'admin'],
                                    (value) => setState(() => _selectedRole = value!),
                                    Icons.badge,
                                    enabled: _isEditing,
                                  ),
                                  _buildDropdownField(
                                    'Level',
                                    _selectedLevel,
                                    ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'],
                                    (value) => setState(() => _selectedLevel = value!),
                                    Icons.school,
                                    enabled: _isEditing,
                                  ),
                                  _buildDropdownField(
                                    'Gender',
                                    _selectedGender ?? 'Not specified',
                                    ['Not specified', 'male', 'female', 'other'],
                                    (value) {
                                      setState(() {
                                        _selectedGender = value == 'Not specified' ? null : value;
                                      });
                                    },
                                    Icons.people,
                                    enabled: _isEditing,
                                  ),
                                  _buildInfoField('Date of Birth', _dobController, Icons.calendar_today,
                                      enabled: _isEditing, hint: 'YYYY-MM-DD'),
                                  _buildInfoField('Native Language', _nativeLangController, Icons.language,
                                      enabled: _isEditing),
                                  _buildInfoField('Learning Goal', _learningGoalController, Icons.flag,
                                      enabled: _isEditing),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildSection(
                                'Statistics',
                                Icons.analytics,
                                [
                                  _buildInfoField('Points', _pointsController, Icons.stars, enabled: _isEditing, isNumber: true),
                                  _buildInfoField('Current Streak', _streakController, Icons.local_fire_department,
                                      enabled: _isEditing, isNumber: true),
                                  _buildInfoField('Longest Streak', _longestStreakController, Icons.emoji_events,
                                      enabled: _isEditing, isNumber: true),
                                  _buildReadOnlyField('Age', _calculateAge(user['dateOfBirth'] as String?) ?? 'N/A', Icons.cake),
                                  _buildReadOnlyField('Created At', _formatDate(createdAt), Icons.calendar_today),
                                  _buildReadOnlyField('Last Activity', _formatDate(lastActivity), Icons.access_time),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildSection(
                                'Pro Status',
                                Icons.star,
                                [
                                  SwitchListTile(
                                    title: const Text('Pro User'),
                                    subtitle: const Text('Enable or disable Pro status'),
                                    value: _isPro,
                                    onChanged: _isEditing
                                        ? (value) {
                                            setState(() {
                                              _isPro = value;
                                            });
                                          }
                                        : null,
                                    activeColor: Colors.amber,
                                  ),
                                  if (_isPro)
                                    _isEditing
                                        ? _buildInfoField('Pro Expires At', _proExpiresController, Icons.event,
                                            enabled: true, hint: 'YYYY-MM-DD')
                                        : _buildReadOnlyField('Pro Expires At', _formatDate(user['proExpiresAt'] as String?), Icons.event),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Actions
                              Card(
                                color: AppColors.errorRed.withOpacity(0.1),
                                child: ListTile(
                                  leading: Icon(Icons.delete, color: AppColors.errorRed),
                                  title: Text('Delete User', style: TextStyle(color: AppColors.errorRed)),
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete User'),
                                        content: Text('Are you sure you want to delete $name? This action cannot be undone.'),
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
                                          Navigator.of(context).pop(true);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('User deleted successfully'),
                                              backgroundColor: AppColors.successGreen,
                                            ),
                                          );
                                        }
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(result['error'] as String? ?? 'Failed to delete user'),
                                              backgroundColor: AppColors.errorRed,
                                            ),
                                          );
                                        }
                                      }
                                    }
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

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = false,
    String? hint,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.grey600, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          enabled
              ? TextField(
                  controller: controller,
                  keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.text.isEmpty ? 'N/A' : controller.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.grey600, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    IconData icon, {
    bool enabled = false,
  }) {
    // Ensure value exists in items list to avoid assertion error
    final validValue = items.contains(value) ? value : (items.isNotEmpty ? items[0] : null);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.grey600, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          enabled
              ? DropdownButtonFormField<String>(
                  value: validValue,
                  items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
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
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          // For Google images, use User-Agent header
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
