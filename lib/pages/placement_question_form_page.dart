import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/placement_service.dart';

class PlacementQuestionFormPage extends StatefulWidget {
  final Map<String, dynamic>? question;

  const PlacementQuestionFormPage({super.key, this.question});

  @override
  State<PlacementQuestionFormPage> createState() => _PlacementQuestionFormPageState();
}

class _PlacementQuestionFormPageState extends State<PlacementQuestionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionTextController = TextEditingController();
  final _weightController = TextEditingController();
  final _maxPointsController = TextEditingController();
  final _pointsController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _correctTextController = TextEditingController();
  
  String _selectedType = 'vocabulary';
  String _selectedSkill = 'vocabulary';
  String? _selectedMainLevel;
  String? _selectedSubLevel;
  bool _isLoading = false;
  
  // Options for MCQ types
  final List<Map<String, dynamic>> _options = [
    {'key': 'A', 'text': TextEditingController()},
    {'key': 'B', 'text': TextEditingController()},
    {'key': 'C', 'text': TextEditingController()},
    {'key': 'D', 'text': TextEditingController()},
  ];
  String? _correctKey;
  
  // True/False options (separate from MCQ)
  final List<Map<String, dynamic>> _trueFalseOptions = [
    {'key': 'True', 'text': TextEditingController()},
    {'key': 'False', 'text': TextEditingController()},
  ];
  
  List<Map<String, dynamic>> get _activeOptions {
    if (_selectedType == 'true_false') {
      // True/False: only 2 options
      return _trueFalseOptions;
    } else if (_selectedType == 'vocabulary' || _selectedType == 'grammar' || 
               _selectedType == 'reading' || _selectedType == 'listening') {
      // MCQ: 4 options
      return _options;
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionTextController.text = widget.question!['questionTextEN'] as String? ?? '';
      _selectedType = widget.question!['type'] as String? ?? 'vocabulary';
      _selectedSkill = widget.question!['skill'] as String? ?? 'vocabulary';
      _selectedMainLevel = widget.question!['mainLevel'] as String?;
      _selectedSubLevel = widget.question!['subLevel'] as String?;
      _weightController.text = widget.question!['weight']?.toString() ?? '';
      _maxPointsController.text = widget.question!['maxPoints']?.toString() ?? '';
      _pointsController.text = widget.question!['points']?.toString() ?? '1';
      _mediaUrlController.text = widget.question!['mediaUrl'] as String? ?? '';
      _audioUrlController.text = widget.question!['audioUrl'] as String? ?? '';
      _imageUrlController.text = widget.question!['imageUrl'] as String? ?? '';
      _correctTextController.text = widget.question!['correctText'] as String? ?? '';
      _correctKey = widget.question!['correctKey'] as String?;
      
      final options = widget.question!['options'] as List<dynamic>? ?? [];
      if (_selectedType == 'true_false') {
        // True/False: initialize with True/False values
        if (options.length >= 2) {
          (_trueFalseOptions[0]['text'] as TextEditingController).text = options[0]['text'] as String? ?? 'True';
          (_trueFalseOptions[1]['text'] as TextEditingController).text = options[1]['text'] as String? ?? 'False';
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
        }
      }
    } else {
      // Initialize defaults for new questions
      _pointsController.text = '1';
      if (_selectedType == 'true_false') {
        (_trueFalseOptions[0]['text'] as TextEditingController).text = 'True';
        (_trueFalseOptions[1]['text'] as TextEditingController).text = 'False';
      }
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _weightController.dispose();
    _maxPointsController.dispose();
    _pointsController.dispose();
    _mediaUrlController.dispose();
    _audioUrlController.dispose();
    _imageUrlController.dispose();
    _correctTextController.dispose();
    for (var opt in _options) {
      (opt['text'] as TextEditingController).dispose();
    }
    for (var opt in _trueFalseOptions) {
      (opt['text'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'questionTextEN': _questionTextController.text.trim(),
      'type': _selectedType,
      'skill': _selectedSkill,
    };

    if (_selectedMainLevel != null) {
      data['mainLevel'] = _selectedMainLevel;
    }
    if (_selectedSubLevel != null) {
      data['subLevel'] = _selectedSubLevel;
    }
    if (_weightController.text.isNotEmpty) {
      final weight = double.tryParse(_weightController.text);
      if (weight != null) {
        data['weight'] = weight;
      }
    }
    if (_maxPointsController.text.isNotEmpty) {
      final maxPoints = double.tryParse(_maxPointsController.text);
      if (maxPoints != null) {
        data['maxPoints'] = maxPoints;
      }
    }
    if (_pointsController.text.isNotEmpty) {
      final points = double.tryParse(_pointsController.text);
      if (points != null) {
        data['points'] = points;
      }
    }

    if (_mediaUrlController.text.isNotEmpty) {
      data['mediaUrl'] = _mediaUrlController.text.trim();
    }
    if (_audioUrlController.text.isNotEmpty) {
      data['audioUrl'] = _audioUrlController.text.trim();
    }
    if (_imageUrlController.text.isNotEmpty) {
      data['imageUrl'] = _imageUrlController.text.trim();
    }

    // Add options for MCQ and True/False types
    if (_selectedType == 'vocabulary' || _selectedType == 'grammar' || 
        _selectedType == 'reading' || _selectedType == 'listening' || _selectedType == 'true_false') {
      final options = _activeOptions.map((opt) {
        return <String, dynamic>{
          'key': opt['key'] as String,
          'text': (opt['text'] as TextEditingController).text.trim(),
        };
      }).toList();
      data['options'] = options;
      if (_correctKey != null) {
        data['correctKey'] = _correctKey;
      }
    }

    // Add correctText for writing
    if (_selectedType == 'writing') {
      if (_correctTextController.text.isNotEmpty) {
        data['correctText'] = _correctTextController.text.trim();
      }
    }

    final result = widget.question != null
        ? await PlacementService.update(
            widget.question!['_id'] as String? ?? widget.question!['id'] as String? ?? '',
            data,
          )
        : await PlacementService.create(data);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.question != null
                ? 'Placement question updated successfully'
                : 'Placement question created successfully'),
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
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedType,
                                          decoration: const InputDecoration(
                                            labelText: 'Type',
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'vocabulary', child: Text('Vocabulary')),
                                            DropdownMenuItem(value: 'grammar', child: Text('Grammar')),
                                            DropdownMenuItem(value: 'reading', child: Text('Reading')),
                                            DropdownMenuItem(value: 'listening', child: Text('Listening')),
                                            DropdownMenuItem(value: 'writing', child: Text('Writing')),
                                            DropdownMenuItem(value: 'true_false', child: Text('True/False')),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedType = value ?? 'vocabulary';
                                              _selectedSkill = _selectedType;
                                              // Reset correct key when type changes
                                              _correctKey = null;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: DropdownButtonFormField<String?>(
                                          value: _selectedMainLevel,
                                          decoration: const InputDecoration(
                                            labelText: 'Main Level (Optional)',
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: null, child: Text('None')),
                                            DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                                            DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
                                            DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedMainLevel = value;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: DropdownButtonFormField<String?>(
                                          value: _selectedSubLevel,
                                          decoration: const InputDecoration(
                                            labelText: 'Sub-Level (Optional)',
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: null, child: Text('None')),
                                            DropdownMenuItem(value: 'LOW', child: Text('Low')),
                                            DropdownMenuItem(value: 'MID', child: Text('Mid')),
                                            DropdownMenuItem(value: 'HIGH', child: Text('High')),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedSubLevel = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _questionTextController,
                                    decoration: const InputDecoration(
                                      labelText: 'Question Text (English)',
                                    ),
                                    maxLines: 3,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter question text';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _weightController,
                                          decoration: const InputDecoration(
                                            labelText: 'Weight (Optional)',
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _maxPointsController,
                                          decoration: const InputDecoration(
                                            labelText: 'Max Points (Optional)',
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _pointsController,
                                          decoration: const InputDecoration(
                                            labelText: 'Points (Legacy)',
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Required';
                                            }
                                            if (double.tryParse(value) == null) {
                                              return 'Must be a number';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _mediaUrlController,
                                          decoration: const InputDecoration(
                                            labelText: 'Media URL (Optional)',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _audioUrlController,
                                          decoration: const InputDecoration(
                                            labelText: 'Audio URL (Optional)',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _imageUrlController,
                                    decoration: const InputDecoration(
                                      labelText: 'Image URL (Optional)',
                                    ),
                                  ),
                                  if (_selectedType == 'vocabulary' || _selectedType == 'grammar' || 
                                      _selectedType == 'reading' || _selectedType == 'listening' || _selectedType == 'true_false') ...[
                                    const SizedBox(height: 24),
                                    Text(
                                      'Options',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 16),
                                    ..._activeOptions.map((opt) {
                                      final key = opt['key'] as String;
                                      final textController = opt['text'] as TextEditingController;
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
                                  if (_selectedType == 'writing') ...[
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _correctTextController,
                                      decoration: const InputDecoration(
                                        labelText: 'Correct Answer (Optional)',
                                      ),
                                      maxLines: 3,
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
