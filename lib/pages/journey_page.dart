import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/journey_service.dart';
import '../services/placement_service.dart';
import 'journey_stage_form_page.dart';
import 'journey_stage_detail_page.dart';
import 'placement_question_form_page.dart';

class JourneyPage extends StatefulWidget {
  const JourneyPage({super.key});

  @override
  State<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _stages = [];
  List<dynamic> _placementQuestions = [];
  bool _isLoadingStages = false;
  bool _isLoadingPlacement = false;
  
  // Filter states
  String? _selectedLevelFilter;
  String? _selectedSubLevelFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlacementQuestions(); // Load placement questions by default (first tab)
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStages() async {
    setState(() => _isLoadingStages = true);
    final result = await JourneyService.getAllStages();
    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        if (data is Map) {
          _stages = data['data'] as List<dynamic>? ?? [];
        } else if (data is List) {
          _stages = data;
        } else {
          _stages = [];
        }
        _isLoadingStages = false;
      });
    } else {
      setState(() => _isLoadingStages = false);
    }
  }

  Future<void> _loadPlacementQuestions() async {
    setState(() => _isLoadingPlacement = true);
    final result = await PlacementService.getAll();
    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        if (data is Map) {
          _placementQuestions = data['data'] as List<dynamic>? ?? [];
        } else if (data is List) {
          _placementQuestions = data;
        } else {
          _placementQuestions = [];
        }
        _isLoadingPlacement = false;
      });
    } else {
      setState(() => _isLoadingPlacement = false);
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
            Sidebar(currentRoute: '/journey'),
            Expanded(
              child: Column(
                children: [
                  const app_bar.AppBar(),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
                                tooltip: 'Back to Dashboard',
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Journey',
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                            ],
                          ),
                        ),
                        TabBar(
                          controller: _tabController,
                          onTap: (index) {
                            if (index == 0) _loadPlacementQuestions();
                            if (index == 1) _loadStages();
                          },
                          tabs: const [
                            Tab(text: 'Placement Test'),
                            Tab(text: 'Journey'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildPlacementTab(),
                              _buildJourneyTab(),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildPlacementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Placement Test Questions',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These questions are used for the level placement test',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PlacementQuestionFormPage(),
                    ),
                  );
                  if (result == true) {
                    _loadPlacementQuestions();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingPlacement)
            const Center(child: CircularProgressIndicator())
          else if (_placementQuestions.isEmpty)
            Center(
              child: Text(
                'No placement questions found',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _placementQuestions.map((question) {
                final questionText = question['questionTextEN'] as String? ?? '';
                final type = question['type'] as String? ?? '';
                final mainLevel = question['mainLevel'] as String? ?? '';
                final subLevel = question['subLevel'] as String? ?? '';
                final levelText = mainLevel.isNotEmpty && subLevel.isNotEmpty
                    ? '$mainLevel-$subLevel'
                    : mainLevel.isNotEmpty
                        ? mainLevel
                        : 'N/A';
                final id = question['_id'] as String? ?? question['id'] as String? ?? '';
                return SizedBox(
                  width: 350,
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  questionText,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.grey600.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  levelText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.grey700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: AppColors.primaryGreen,
                                onPressed: () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PlacementQuestionFormPage(
                                        question: question as Map<String, dynamic>,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadPlacementQuestions();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                color: AppColors.errorRed,
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Question'),
                                      content: const Text('Are you sure?'),
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
                                    final result = await PlacementService.delete(id);
                                    if (result['success'] == true) {
                                      _loadPlacementQuestions();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Question deleted successfully')),
                                        );
                                      }
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(result['error'] as String? ?? 'Failed to delete question')),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildJourneyTab() {
    // Apply filters
    List<dynamic> filteredStages = _stages;
    
    if (_selectedLevelFilter != null) {
      filteredStages = filteredStages.where((stage) {
        return stage['levelId'] == _selectedLevelFilter;
      }).toList();
    }
    
    if (_selectedSubLevelFilter != null) {
      filteredStages = filteredStages.where((stage) {
        final subLevel = (stage['subLevel'] as String? ?? '').toLowerCase();
        return subLevel == _selectedSubLevelFilter!.toLowerCase();
      }).toList();
    }

    // Group filtered stages by level
    final Map<String, List<dynamic>> stagesByLevel = {};
    for (var stage in filteredStages) {
      final levelId = stage['levelId'] as String? ?? 'UNKNOWN';
      if (!stagesByLevel.containsKey(levelId)) {
        stagesByLevel[levelId] = [];
      }
      stagesByLevel[levelId]!.add(stage);
    }

    // Sort stages within each level by stageNumber
    stagesByLevel.forEach((level, stages) {
      stages.sort((a, b) {
        final aNum = a['stageNumber'] as int? ?? 0;
        final bNum = b['stageNumber'] as int? ?? 0;
        return aNum.compareTo(bNum);
      });
    });

    // Define level order and colors
    final levelOrder = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'];
    final levelColors = {
      'BEGINNER': AppColors.successGreen,
      'INTERMEDIATE': AppColors.primaryGreen,
      'ADVANCED': AppColors.darkGreen,
    };
    
    // Get unique sub-levels from filtered stages
    final subLevels = filteredStages
        .map((s) => s['subLevel'] as String?)
        .where((s) => s != null && s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Journey Stages',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const JourneyStageFormPage(),
                    ),
                  );
                  if (result == true) {
                    _loadStages();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('New Stage'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: AppColors.primaryGreen),
                  const SizedBox(width: 12),
                  Text(
                    'Filters:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedLevelFilter,
                      decoration: const InputDecoration(
                        labelText: 'Level',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Levels')),
                        const DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                        const DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
                        const DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLevelFilter = value;
                          // Reset sub-level filter when level changes
                          if (value == null) {
                            _selectedSubLevelFilter = null;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedSubLevelFilter,
                      decoration: const InputDecoration(
                        labelText: 'Sub-Level',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Sub-Levels')),
                        ...subLevels.map((subLevel) => DropdownMenuItem(
                              value: subLevel,
                              child: Text((subLevel ?? '').toUpperCase()),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSubLevelFilter = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_selectedLevelFilter != null || _selectedSubLevelFilter != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedLevelFilter = null;
                          _selectedSubLevelFilter = null;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoadingStages)
            const Center(child: CircularProgressIndicator())
          else if (_stages.isEmpty)
            Center(
              child: Text(
                'No stages found',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          else if (filteredStages.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_alt_off, size: 64, color: AppColors.grey600),
                  const SizedBox(height: 16),
                  Text(
                    'No stages match the selected filters',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedLevelFilter = null;
                        _selectedSubLevelFilter = null;
                      });
                    },
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            )
          else
            ...levelOrder.map((level) {
              final levelStages = stagesByLevel[level] ?? [];
              if (levelStages.isEmpty) return const SizedBox.shrink();

              final levelColor = levelColors[level] ?? AppColors.primaryGreen;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: levelColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: levelColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            level,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${levelStages.length} ${levelStages.length == 1 ? 'Stage' : 'Stages'}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: levelColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: levelStages.map((stage) {
                      final stageNumber = stage['stageNumber'] as int? ?? 0;
                      final levelId = stage['levelId'] as String? ?? '';
                      final subLevel = stage['subLevel'] as String? ?? '';
                      final questionsCount = stage['questionsCount'] as int? ?? 0;
                      final id = stage['_id'] as String? ?? stage['id'] as String? ?? '';
                      final isActive = stage['isActive'] as bool? ?? true;
                      final videoUrl = stage['videoUrl'] as String?;
                      final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

                      return SizedBox(
                        width: 320,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: hasVideo
                                ? BorderSide(color: AppColors.primaryGreen.withOpacity(0.3), width: 2)
                                : BorderSide.none,
                          ),
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => JourneyStageDetailPage(stage: stage as Map<String, dynamic>),
                                ),
                              );
                              if (result == true) {
                                _loadStages();
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: levelColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$stageNumber',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: levelColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Stage $stageNumber',
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                              Text(
                                                (subLevel?.isNotEmpty ?? false) ? subLevel!.toUpperCase() : levelId,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: AppColors.grey600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (hasVideo)
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryGreen.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.video_library,
                                            size: 20,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      if (!isActive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.grey600.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Inactive',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.grey700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.quiz_outlined, size: 16, color: AppColors.grey600),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$questionsCount questions',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.grey600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility, size: 20),
                                        color: AppColors.primaryGreen,
                                        tooltip: 'View Details',
                                        onPressed: () async {
                                          final result = await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => JourneyStageDetailPage(stage: stage as Map<String, dynamic>),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadStages();
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        color: AppColors.primaryGreen,
                                        onPressed: () async {
                                          final result = await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => JourneyStageFormPage(
                                                stage: stage as Map<String, dynamic>,
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadStages();
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20),
                                        color: AppColors.errorRed,
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Stage'),
                                              content: const Text('Are you sure?'),
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
                                            final result = await JourneyService.deleteStage(id);
                                            if (result['success'] == true) {
                                              _loadStages();
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Stage deleted successfully')),
                                                );
                                              }
                                            } else {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(result['error'] as String? ?? 'Failed to delete stage')),
                                                );
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

}
