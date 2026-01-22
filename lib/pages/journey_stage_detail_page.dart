import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/journey_service.dart';
import 'journey_stage_form_page.dart';
import 'journey_question_form_page.dart';

class JourneyStageDetailPage extends StatefulWidget {
  final Map<String, dynamic> stage;

  const JourneyStageDetailPage({super.key, required this.stage});

  @override
  State<JourneyStageDetailPage> createState() => _JourneyStageDetailPageState();
}

class _JourneyStageDetailPageState extends State<JourneyStageDetailPage> {
  Map<String, dynamic>? _stage;
  List<dynamic> _questions = [];
  bool _isLoadingStage = false;
  bool _isLoadingQuestions = false;
  final _videoUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stage = widget.stage;
    _videoUrlController.text = _stage!['videoUrl'] as String? ?? '';
    _loadQuestions();
  }

  @override
  void dispose() {
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _refreshStage() async {
    // Reload all stages and find the current one
    setState(() => _isLoadingStage = true);
    final result = await JourneyService.getAllStages();
    if (result['success'] == true) {
      final data = result['data'];
      List<dynamic> stages = [];
      if (data is Map) {
        stages = data['data'] as List<dynamic>? ?? [];
      } else if (data is List) {
        stages = data;
      }
      
      final currentId = _stage!['_id'] as String? ?? _stage!['id'] as String? ?? '';
      final updatedStage = stages.firstWhere(
        (s) => (s['_id'] as String? ?? s['id'] as String? ?? '') == currentId,
        orElse: () => _stage!,
      );
      
      setState(() {
        _stage = updatedStage as Map<String, dynamic>? ?? _stage;
        if (_stage != null) {
          _videoUrlController.text = _stage!['videoUrl'] as String? ?? '';
        }
        _isLoadingStage = false;
      });
    } else {
      setState(() => _isLoadingStage = false);
    }
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoadingQuestions = true);
    final levelId = _stage!['levelId'] as String? ?? '';
    final stageNumber = _stage!['stageNumber'] as int? ?? 0;
    final result = await JourneyService.getAllQuestions(level: levelId, stage: stageNumber);
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
        _isLoadingQuestions = false;
      });
    } else {
      setState(() => _isLoadingQuestions = false);
    }
  }

  Future<void> _updateVideoUrl() async {
    if (_stage == null) return;
    
    final id = _stage!['_id'] as String? ?? _stage!['id'] as String? ?? '';
    final videoUrl = _videoUrlController.text.trim();
    
    final result = await JourneyService.updateStage(id, {'videoUrl': videoUrl.isEmpty ? null : videoUrl});
    
    if (result['success'] == true) {
      setState(() {
        _stage!['videoUrl'] = videoUrl.isEmpty ? null : videoUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video URL updated successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Failed to update video URL')),
        );
      }
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    if (_questions.length <= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete: Stage must have at least 5 questions'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure? This will reduce the number of questions.'),
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
      final result = await JourneyService.deleteQuestion(questionId);
      if (result['success'] == true) {
        _loadQuestions();
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
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == null) {
      return Scaffold(
        backgroundColor: AppColors.beige,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final stageNumber = _stage!['stageNumber'] as int? ?? 0;
    final levelId = _stage!['levelId'] as String? ?? '';
    final subLevel = _stage!['subLevel'] as String? ?? '';
    final questionsCount = _stage!['questionsCount'] as int? ?? 0;
    final videoUrl = _stage!['videoUrl'] as String?;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

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
          Sidebar(currentRoute: '/journey'),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stage $stageNumber',
                                  style: Theme.of(context).textTheme.displayMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Level: $levelId | Sub-Level: $subLevel | Questions: $questionsCount',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.grey600,
                                      ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => JourneyStageFormPage(
                                          stage: _stage!,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _refreshStage();
                                    }
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Stage'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Stage'),
                                        content: const Text('Are you sure? This will delete the stage and all its questions.'),
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
                                      final id = _stage!['_id'] as String? ?? _stage!['id'] as String? ?? '';
                                      final result = await JourneyService.deleteStage(id);
                                      if (result['success'] == true) {
                                        if (mounted) {
                                          Navigator.of(context).pop(true);
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
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Video Section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Video',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    if (hasVideo)
                                      TextButton.icon(
                                        onPressed: () async {
                                          _videoUrlController.clear();
                                          await _updateVideoUrl();
                                        },
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Remove'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.errorRed,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (hasVideo) ...[
                                  Text(
                                    'Current Video:',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    videoUrl!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.primaryGreen,
                                          decoration: TextDecoration.underline,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Change Video URL'),
                                          content: TextField(
                                            controller: _videoUrlController,
                                            decoration: const InputDecoration(
                                              labelText: 'Video URL',
                                              hintText: 'https://example.com/video.mp4',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _updateVideoUrl();
                                              },
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Change'),
                                  ),
                                ] else ...[
                                  Text(
                                    'No video added yet',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.grey600,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Add Video URL'),
                                          content: TextField(
                                            controller: _videoUrlController,
                                            decoration: const InputDecoration(
                                              labelText: 'Video URL',
                                              hintText: 'https://example.com/video.mp4',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _updateVideoUrl();
                                              },
                                              child: const Text('Add'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Video'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Questions Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Questions (${_questions.length})',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => JourneyQuestionFormPage(
                                      levelId: levelId,
                                      stageNumber: stageNumber,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadQuestions();
                                  _refreshStage(); // Update questionsCount
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Question'),
                            ),
                          ],
                        ),
                        if (_questions.length < 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            child: Text(
                              '⚠️ Stage must have at least 5 questions (currently ${_questions.length})',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.errorRed,
                                  ),
                            ),
                          )
                        else
                          const SizedBox(height: 16),
                        if (_isLoadingQuestions)
                          const Center(child: CircularProgressIndicator())
                        else if (_questions.isEmpty)
                          Center(
                            child: Text(
                              'No questions found',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.start,
                            children: _questions.map((question) {
                              final order = question['order'] as int? ?? 0;
                              final prompt = question['prompt'] as String? ?? '';
                              final type = question['type'] as String? ?? '';
                              final points = question['points'] as int? ?? 0;
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
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGreen.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$order',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primaryGreen,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                prompt,
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
                                            Row(
                                              children: [
                                                Icon(Icons.star_outline, size: 14, color: AppColors.grey600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$points pts',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.grey700,
                                                  ),
                                                ),
                                              ],
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
                                              icon: const Icon(Icons.delete, size: 20),
                                              color: AppColors.errorRed,
                                              onPressed: () => _deleteQuestion(id),
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
                        const SizedBox(height: 24), // Add bottom padding to prevent overflow
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
}
