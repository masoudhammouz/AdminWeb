import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/letter_sounds_service.dart';
import 'letter_sound_form_page.dart';

class LetterSoundsPage extends StatefulWidget {
  const LetterSoundsPage({super.key});

  @override
  State<LetterSoundsPage> createState() => _LetterSoundsPageState();
}

class _LetterSoundsPageState extends State<LetterSoundsPage> {
  List<dynamic> _letterSounds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLetterSounds();
  }

  Future<void> _loadLetterSounds() async {
    setState(() => _isLoading = true);
    final result = await LetterSoundsService.getAllLetterSounds();
    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        if (data is Map) {
          _letterSounds = data['data'] as List<dynamic>? ?? [];
        } else if (data is List) {
          _letterSounds = data;
        } else {
          _letterSounds = [];
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLetterSound(String id, String letter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Letter Sound'),
        content: Text('Are you sure you want to delete letter "$letter"?'),
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
      final result = await LetterSoundsService.deleteLetterSound(id);
      if (result['success'] == true) {
        _loadLetterSounds();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Letter sound deleted successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] as String? ?? 'Failed to delete letter sound')),
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
            Sidebar(currentRoute: '/letter-sounds'),
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
                                    'Letter Sounds',
                                    style: Theme.of(context).textTheme.displayMedium,
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const LetterSoundFormPage(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadLetterSounds();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('New Letter Sound'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _letterSounds.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.abc_outlined, size: 64, color: AppColors.grey600),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No letter sounds found',
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
                                          itemCount: _letterSounds.length,
                                          itemBuilder: (context, index) {
                                            final letterSound = _letterSounds[index];
                                            final letter = letterSound['letter'] as String? ?? '';
                                            final order = letterSound['order'] as int? ?? 0;
                                            final difficulty = letterSound['difficulty'] as String? ?? 'easy';
                                            final difficultyLevel = letterSound['difficultyLevel'] as int? ?? 1;
                                            final id = letterSound['_id'] as String? ?? letterSound['id'] as String? ?? '';
                                            
                                            // Get difficulty color
                                            Color difficultyColor;
                                            switch (difficulty.toLowerCase()) {
                                              case 'easy':
                                                difficultyColor = AppColors.successGreen;
                                                break;
                                              case 'medium':
                                                difficultyColor = Colors.orange;
                                                break;
                                              case 'hard':
                                                difficultyColor = AppColors.errorRed;
                                                break;
                                              default:
                                                difficultyColor = AppColors.grey600;
                                            }
                                            
                                            return Card(
                                              elevation: 3,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: InkWell(
                                                onTap: () async {
                                                  final result = await Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => LetterSoundFormPage(
                                                        letterSound: letterSound as Map<String, dynamic>,
                                                      ),
                                                    ),
                                                  );
                                                  if (result == true) {
                                                    _loadLetterSounds();
                                                  }
                                                },
                                                borderRadius: BorderRadius.circular(16),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(16),
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [
                                                        AppColors.primaryGreen.withOpacity(0.05),
                                                        AppColors.darkGreen.withOpacity(0.05),
                                                      ],
                                                    ),
                                                  ),
                                                  padding: const EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 48,
                                                            height: 48,
                                                            decoration: BoxDecoration(
                                                              color: AppColors.primaryGreen.withOpacity(0.15),
                                                              borderRadius: BorderRadius.circular(12),
                                                              border: Border.all(
                                                                color: AppColors.primaryGreen.withOpacity(0.3),
                                                                width: 2,
                                                              ),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                letter,
                                                                style: TextStyle(
                                                                  fontSize: 28,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: AppColors.primaryGreen,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  'Letter',
                                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                        color: AppColors.grey600,
                                                                        fontSize: 11,
                                                                      ),
                                                                ),
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  letter,
                                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 18,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: difficultyColor.withOpacity(0.2),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              difficulty.toUpperCase(),
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                                color: difficultyColor,
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
                                                      _buildInfoRow(Icons.sort, 'Order', order.toString()),
                                                      const SizedBox(height: 4),
                                                      _buildInfoRow(Icons.school, 'Level', difficultyLevel.toString()),
                                                      const Spacer(),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.edit),
                                                            iconSize: 18,
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(),
                                                            onPressed: () async {
                                                              final result = await Navigator.of(context).push(
                                                                MaterialPageRoute(
                                                                  builder: (_) => LetterSoundFormPage(
                                                                    letterSound: letterSound as Map<String, dynamic>,
                                                                  ),
                                                                ),
                                                              );
                                                              if (result == true) {
                                                                _loadLetterSounds();
                                                              }
                                                            },
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.delete),
                                                            iconSize: 18,
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(),
                                                            color: AppColors.errorRed,
                                                            onPressed: () => _deleteLetterSound(id, letter),
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
