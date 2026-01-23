import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/journey_service.dart';

class JourneyQuestionFormPage extends StatefulWidget {
  final Map<String, dynamic>? question;
  final String? levelId;
  final int? stageNumber;

  const JourneyQuestionFormPage({
    super.key,
    this.question,
    this.levelId,
    this.stageNumber,
  });

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
  
  // Options for MCQ and True/False
  final List<Map<String, dynamic>> _options = [
    {'key': 'A', 'text': TextEditingController(), 'audioUrl': TextEditingController()},
    {'key': 'B', 'text': TextEditingController(), 'audioUrl': TextEditingController()},
    {'key': 'C', 'text': TextEditingController(), 'audioUrl': TextEditingController()},
    {'key': 'D', 'text': TextEditingController(), 'audioUrl': TextEditingController()},
  ];
  String? _correctKey;
  
  // True/False options (separate from MCQ)
  final List<Map<String, dynamic>> _trueFalseOptions = [
    {'key': 'True', 'text': TextEditingController(), 'audioUrl': TextEditingController()},
    {'key': 'False', 'text': TextEditingController(), 'audioUrl': TextEditingController()},
  ];
  
  List<Map<String, dynamic>> get _activeOptions {
    if (_selectedType == 'true_false') {
      // True/False: only 2 options
      return _trueFalseOptions;
    } else if (_selectedType == 'mcq' || _selectedType == 'listening_mcq' || _selectedType == 'image_mcq') {
      // MCQ: 4 options
      return _options;
    }
    return [];
  }

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
      final questionType = widget.question!['type'] as String? ?? 'mcq';
      // Validate type exists in dropdown items
      final validTypes = ['mcq', 'listening_mcq', 'image_mcq', 'fill_blank', 'writing', 'true_false'];
      _selectedType = validTypes.contains(questionType) ? questionType : 'mcq';
      _stageNumber = widget.question!['stageNumber'] as int? ?? 1;
      _isActive = widget.question!['isActive'] as bool? ?? true;
      _correctKey = widget.question!['correctKey'] as String?;
      
      final options = widget.question!['options'] as List<dynamic>? ?? [];
      if (questionType == 'true_false') {
        // True/False: initialize with True/False values
        if (options.length >= 2) {
          (_trueFalseOptions[0]['text'] as TextEditingController).text = options[0]['text'] as String? ?? 'True';
          (_trueFalseOptions[1]['text'] as TextEditingController).text = options[1]['text'] as String? ?? 'False';
          (_trueFalseOptions[0]['audioUrl'] as TextEditingController).text = options[0]['audioUrl'] as String? ?? '';
          (_trueFalseOptions[1]['audioUrl'] as TextEditingController).text = options[1]['audioUrl'] as String? ?? '';
        } else {
          // Initialize defaults
          (_trueFalseOptions[0]['text'] as TextEditingController).text = 'True';
          (_trueFalseOptions[1]['text'] as TextEditingController).text = 'False';
        }
      } else {
        // MCQ: use regular options
        for (var i = 0; i < _options.length && i < options.length; i++) {
          final opt = options[i];
          (_options[i]['text'] as TextEditingController).text = opt['text'] as String? ?? '';
          (_options[i]['audioUrl'] as TextEditingController).text = opt['audioUrl'] as String? ?? '';
        }
      }
    } else {
      // If opened from stage detail, use provided levelId and stageNumber
      if (widget.levelId != null) {
        _selectedLevel = widget.levelId!;
      }
      if (widget.stageNumber != null) {
        _stageNumber = widget.stageNumber!;
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
    for (var opt in _trueFalseOptions) {
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

    // Add options for MCQ and True/False types
    if (_selectedType == 'mcq' || _selectedType == 'listening_mcq' || _selectedType == 'image_mcq' || _selectedType == 'true_false') {
      final options = _activeOptions.map((opt) {
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
                                        child: widget.levelId != null && widget.question == null
                                            ? TextFormField(
                                                controller: TextEditingController(text: _selectedLevel),
                                                decoration: const InputDecoration(
                                                  labelText: 'Level',
                                                ),
                                                enabled: false,
                                              )
                                            : DropdownButtonFormField<String>(
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
                                        child: widget.stageNumber != null && widget.question == null
                                            ? TextFormField(
                                                controller: TextEditingController(text: _stageNumber.toString()),
                                                decoration: const InputDecoration(
                                                  labelText: 'Stage Number',
                                                ),
                                                enabled: false,
                                              )
                                            : TextFormField(
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
                                        // Reset correct key when type changes
                                        _correctKey = null;
                                        // Initialize True/False options if needed
                                        if (_selectedType == 'true_false') {
                                          // Options will be handled by _activeOptions getter
                                        }
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
                                  if (_selectedType == 'mcq' || _selectedType == 'listening_mcq' || _selectedType == 'image_mcq' || _selectedType == 'true_false') ...[
                                    const SizedBox(height: 24),
                                    Text(
                                      'Options',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 16),
                                    ..._activeOptions.map((opt) {
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
                                              if (_selectedType != 'true_false') ...[
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
                                              ] else ...[
                                                // True/False: text is fixed, just show it
                                                const SizedBox(height: 8),
                                                TextFormField(
                                                  controller: textController,
                                                  decoration: InputDecoration(
                                                    labelText: 'Option $key',
                                                  ),
                                                  enabled: false,
                                                  style: TextStyle(color: AppColors.grey600),
                                                ),
                                              ],
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
