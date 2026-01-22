import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/journey_service.dart';

class JourneyQuestionFormPage extends StatefulWidget {
  final Map<String, dynamic>? question;

  const JourneyQuestionFormPage({super.key, this.question});

  @override
  State<JourneyQuestionFormPage> createState() => _JourneyQuestionFormPageState();
}

class _JourneyQuestionFormPageState extends State<JourneyQuestionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  final _orderController = TextEditingController();
  final _pointsController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _correctTextController = TextEditingController();
  
  String _selectedLevel = 'BEGINNER';
  String _selectedType = 'mcq';
  int _stageNumber = 1;
  bool _isActive = true;
  bool _isLoading = false;
  
  // Options for MCQ
  final List<Map<String, dynamic>> _options = [
    {'key': 'A', 'text': TextEditingController(), 'audioUrl': TextEditingController()},
    {'key': 'B', 'text': TextEditingController(), 'audioUrl': TextEditingController()},
    {'key': 'C', 'text': TextEditingController(), 'audioUrl': TextEditingController()},
    {'key': 'D', 'text': TextEditingController(), 'audioUrl': TextEditingController()},
  ];
  String? _correctKey;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _promptController.text = widget.question!['prompt'] as String? ?? '';
      _orderController.text = (widget.question!['order'] as int? ?? 1).toString();
      _pointsController.text = (widget.question!['points'] as int? ?? 10).toString();
      _audioUrlController.text = widget.question!['audioUrl'] as String? ?? '';
      _imageUrlController.text = widget.question!['imageUrl'] as String? ?? '';
      _correctTextController.text = widget.question!['correctText'] as String? ?? '';
      _selectedLevel = widget.question!['levelId'] as String? ?? 'BEGINNER';
      _selectedType = widget.question!['type'] as String? ?? 'mcq';
      _stageNumber = widget.question!['stageNumber'] as int? ?? 1;
      _isActive = widget.question!['isActive'] as bool? ?? true;
      _correctKey = widget.question!['correctKey'] as String?;
      
      final options = widget.question!['options'] as List<dynamic>? ?? [];
      for (var i = 0; i < _options.length && i < options.length; i++) {
        final opt = options[i];
        (_options[i]['text'] as TextEditingController).text = opt['text'] as String? ?? '';
        (_options[i]['audioUrl'] as TextEditingController).text = opt['audioUrl'] as String? ?? '';
      }
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _orderController.dispose();
    _pointsController.dispose();
    _audioUrlController.dispose();
    _imageUrlController.dispose();
    _correctTextController.dispose();
    for (var opt in _options) {
      (opt['text'] as TextEditingController).dispose();
      (opt['audioUrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'levelId': _selectedLevel,
      'stageNumber': _stageNumber,
      'order': int.tryParse(_orderController.text) ?? 1,
      'type': _selectedType,
      'prompt': _promptController.text.trim(),
      'points': int.tryParse(_pointsController.text) ?? 10,
      'isActive': _isActive,
    };

    if (_audioUrlController.text.isNotEmpty) {
      data['audioUrl'] = _audioUrlController.text.trim();
    }
    if (_imageUrlController.text.isNotEmpty) {
      data['imageUrl'] = _imageUrlController.text.trim();
    }

    // Add options for MCQ types
    if (_selectedType == 'mcq' || _selectedType == 'listening_mcq' || _selectedType == 'image_mcq') {
      final options = _options.map((opt) {
        final optionData = <String, dynamic>{
          'key': opt['key'] as String,
          'text': (opt['text'] as TextEditingController).text.trim(),
        };
        final audioUrl = (opt['audioUrl'] as TextEditingController).text.trim();
        if (audioUrl.isNotEmpty) {
          optionData['audioUrl'] = audioUrl;
        }
        return optionData;
      }).toList();
      data['options'] = options;
      if (_correctKey != null) {
        data['correctKey'] = _correctKey;
      }
    }

    // Add correctText for fill_blank and writing
    if (_selectedType == 'fill_blank' || _selectedType == 'writing') {
      if (_correctTextController.text.isNotEmpty) {
        data['correctText'] = _correctTextController.text.trim();
      }
    }

    final result = widget.question != null
        ? await JourneyService.updateQuestion(
            widget.question!['_id'] as String? ?? widget.question!['id'] as String? ?? '',
            data,
          )
        : await JourneyService.createQuestion(data);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.question != null
                ? 'Question updated successfully'
                : 'Question created successfully'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Failed to save question')),
        );
      }
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    widget.question != null
                                        ? 'Edit Placement Test Question'
                                        : 'Create Placement Test Question',
                                    style: Theme.of(context).textTheme.displayMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'This question will be used in the level placement test',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.grey600,
                                        ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
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
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _orderController,
                                          decoration: const InputDecoration(
                                            labelText: 'Order',
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Required';
                                            }
                                            if (int.tryParse(value) == null) {
                                              return 'Must be a number';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: TextEditingController(text: _stageNumber.toString()),
                                          decoration: const InputDecoration(
                                            labelText: 'Stage Number',
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            _stageNumber = int.tryParse(value) ?? 1;
                                          },
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Required';
                                            }
                                            if (int.tryParse(value) == null) {
                                              return 'Must be a number';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedType,
                                    decoration: const InputDecoration(
                                      labelText: 'Question Type',
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'mcq', child: Text('Multiple Choice')),
                                      DropdownMenuItem(value: 'listening_mcq', child: Text('Listening MCQ')),
                                      DropdownMenuItem(value: 'image_mcq', child: Text('Image MCQ')),
                                      DropdownMenuItem(value: 'fill_blank', child: Text('Fill in the Blank')),
                                      DropdownMenuItem(value: 'writing', child: Text('Writing')),
                                      DropdownMenuItem(value: 'true_false', child: Text('True/False')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedType = value ?? 'mcq';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _promptController,
                                    decoration: const InputDecoration(
                                      labelText: 'Question/Prompt',
                                    ),
                                    maxLines: 3,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter question';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _audioUrlController,
                                          decoration: const InputDecoration(
                                            labelText: 'Audio URL (Optional)',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _imageUrlController,
                                          decoration: const InputDecoration(
                                            labelText: 'Image URL (Optional)',
                                          ),
                                        ),
                                      ),
                                    ],
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
                                        return 'Required';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Must be a number';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (_selectedType == 'mcq' || _selectedType == 'listening_mcq' || _selectedType == 'image_mcq') ...[
                                    const SizedBox(height: 24),
                                    Text(
                                      'Options',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 16),
                                    ..._options.map((opt) {
                                      final key = opt['key'] as String;
                                      final textController = opt['text'] as TextEditingController;
                                      final audioController = opt['audioUrl'] as TextEditingController;
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: key,
                                                    groupValue: _correctKey,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _correctKey = value;
                                                      });
                                                    },
                                                  ),
                                                  Text(
                                                    'Option $key (${_correctKey == key ? 'Correct' : ''})',
                                                    style: TextStyle(
                                                      fontWeight: _correctKey == key ? FontWeight.bold : FontWeight.normal,
                                                      color: _correctKey == key ? AppColors.primaryGreen : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: textController,
                                                decoration: InputDecoration(
                                                  labelText: 'Text for Option $key',
                                                ),
                                                validator: (value) {
                                                  if (value == null || value.trim().isEmpty) {
                                                    return 'Required';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: audioController,
                                                decoration: InputDecoration(
                                                  labelText: 'Audio URL (Optional)',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    if (_correctKey == null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Text(
                                          'Please select the correct answer',
                                          style: TextStyle(color: AppColors.errorRed),
                                        ),
                                      ),
                                  ],
                                  if (_selectedType == 'fill_blank' || _selectedType == 'writing') ...[
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _correctTextController,
                                      decoration: const InputDecoration(
                                        labelText: 'Correct Answer',
                                      ),
                                      maxLines: 2,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter correct answer';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
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
                                          onPressed: _isLoading ? null : _saveQuestion,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : Text(widget.question != null ? 'Update' : 'Create'),
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
