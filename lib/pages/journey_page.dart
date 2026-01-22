import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/journey_service.dart';
import 'journey_question_form_page.dart';
import 'journey_stage_form_page.dart';

class JourneyPage extends StatefulWidget {
  const JourneyPage({super.key});

  @override
  State<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _stages = [];
  List<dynamic> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStages() async {
    setState(() => _isLoading = true);
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
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final result = await JourneyService.getAllQuestions();
    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        if (data is Map) {
          _questions = data['data'] as List<dynamic>? ?? [];
        } else if (data is List) {
          _questions = data;
        } else {
          _questions = [];
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      TabBar(
                        controller: _tabController,
                        onTap: (index) {
                          if (index == 0) _loadStages();
                          if (index == 1) _loadQuestions();
                        },
                        tabs: const [
                          Tab(text: 'Stages'),
                          Tab(text: 'Questions'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildStagesTab(),
                            _buildQuestionsTab(),
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
    );
  }

  Widget _buildStagesTab() {
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_stages.isEmpty)
            Center(
              child: Text(
                'No stages found',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          else
            ..._stages.map((stage) {
              final stageNumber = stage['stageNumber'] as int? ?? 0;
              final levelId = stage['levelId'] as String? ?? '';
              final subLevel = stage['subLevel'] as String? ?? '';
              final id = stage['_id'] as String? ?? stage['id'] as String? ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('Stage $stageNumber'),
                  subtitle: Text('Level: $levelId | Sub-Level: $subLevel'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
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
                        icon: const Icon(Icons.delete),
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
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab() {
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
                      builder: (_) => const JourneyQuestionFormPage(),
                    ),
                  );
                  if (result == true) {
                    _loadQuestions();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('New Question'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_questions.isEmpty)
            Center(
              child: Text(
                'No questions found',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          else
            Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Question')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Level')),
                  DataColumn(label: Text('Stage')),
                  DataColumn(label: Text('Order')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _questions.map((question) {
                  final prompt = question['prompt'] as String? ?? '';
                  final type = question['type'] as String? ?? '';
                  final levelId = question['levelId'] as String? ?? '';
                  final stageNumber = question['stageNumber'] as int? ?? 0;
                  final order = question['order'] as int? ?? 0;
                  final id = question['_id'] as String? ?? question['id'] as String? ?? '';
                  return DataRow(
                    cells: [
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            prompt,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(type)),
                      DataCell(Text(levelId)),
                      DataCell(Text(stageNumber.toString())),
                      DataCell(Text(order.toString())),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => JourneyQuestionFormPage(
                                      question: question as Map<String, dynamic>,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadQuestions();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
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
                                  await JourneyService.deleteQuestion(id);
                                  _loadQuestions();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
