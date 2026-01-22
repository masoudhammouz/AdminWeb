import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/journey_service.dart';

class JourneyStageFormPage extends StatefulWidget {
  final Map<String, dynamic>? stage;

  const JourneyStageFormPage({super.key, this.stage});

  @override
  State<JourneyStageFormPage> createState() => _JourneyStageFormPageState();
}

class _JourneyStageFormPageState extends State<JourneyStageFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _stageNumberController = TextEditingController();
  final _orderController = TextEditingController();
  final _questionsCountController = TextEditingController();
  
  String _selectedLevel = 'BEGINNER';
  String? _selectedSubLevel;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.stage != null) {
      _selectedLevel = widget.stage!['levelId'] as String? ?? 'BEGINNER';
      _selectedSubLevel = widget.stage!['subLevel'] as String?;
      _stageNumberController.text = (widget.stage!['stageNumber'] as int? ?? 1).toString();
      _orderController.text = (widget.stage!['order'] as int? ?? 1).toString();
      _questionsCountController.text = (widget.stage!['questionsCount'] as int? ?? 5).toString();
      _isActive = widget.stage!['isActive'] as bool? ?? true;
    } else {
      _questionsCountController.text = '5';
    }
  }

  @override
  void dispose() {
    _stageNumberController.dispose();
    _orderController.dispose();
    _questionsCountController.dispose();
    super.dispose();
  }

  Future<void> _saveStage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'level': _selectedLevel.toLowerCase(),
      'stageNumber': int.tryParse(_stageNumberController.text) ?? 1,
      'questionsCount': int.tryParse(_questionsCountController.text) ?? 5,
      'isActive': _isActive,
    };

    if (_selectedSubLevel != null) {
      data['subLevel'] = _selectedSubLevel;
    }
    if (_orderController.text.isNotEmpty) {
      data['order'] = int.tryParse(_orderController.text);
    }

    final result = widget.stage != null
        ? await JourneyService.updateStage(
            widget.stage!['_id'] as String? ?? widget.stage!['id'] as String? ?? '',
            data,
          )
        : await JourneyService.createStage(data);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.stage != null
                ? 'Stage updated successfully'
                : 'Stage created successfully'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Failed to save stage')),
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
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    widget.stage != null
                                        ? 'Edit Journey Stage'
                                        : 'Create Journey Stage',
                                    style: Theme.of(context).textTheme.displayMedium,
                                  ),
                                  const SizedBox(height: 24),
                                  DropdownButtonFormField<String>(
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
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _stageNumberController,
                                          decoration: const InputDecoration(
                                            labelText: 'Stage Number',
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Required';
                                            }
                                            if (int.tryParse(value) == null || int.parse(value) < 1) {
                                              return 'Must be >= 1';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _orderController,
                                          decoration: const InputDecoration(
                                            labelText: 'Order (Optional)',
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String?>(
                                    value: _selectedSubLevel,
                                    decoration: const InputDecoration(
                                      labelText: 'Sub-Level (Optional)',
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: null, child: Text('Auto')),
                                      DropdownMenuItem(value: 'low', child: Text('Low')),
                                      DropdownMenuItem(value: 'mid', child: Text('Mid')),
                                      DropdownMenuItem(value: 'high', child: Text('High')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedSubLevel = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _questionsCountController,
                                    decoration: const InputDecoration(
                                      labelText: 'Questions Count',
                                      hintText: '5',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (int.tryParse(value) == null || int.parse(value) < 1) {
                                        return 'Must be >= 1';
                                      }
                                      return null;
                                    },
                                  ),
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
                                          onPressed: _isLoading ? null : _saveStage,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : Text(widget.stage != null ? 'Update' : 'Create'),
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
