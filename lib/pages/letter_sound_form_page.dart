import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/letter_sounds_service.dart';

class LetterSoundFormPage extends StatefulWidget {
  final Map<String, dynamic>? letterSound;

  const LetterSoundFormPage({super.key, this.letterSound});

  @override
  State<LetterSoundFormPage> createState() => _LetterSoundFormPageState();
}

class _LetterSoundFormPageState extends State<LetterSoundFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _letterController = TextEditingController();
  final _orderController = TextEditingController();
  final _fullAudioUrlController = TextEditingController();
  
  String _selectedDifficulty = 'easy';
  int _selectedDifficultyLevel = 1;
  bool _isLoading = false;
  
  // Sounds controllers
  final List<Map<String, dynamic>> _soundControllers = [
    {'type': 'fatha', 'arabic': TextEditingController(), 'latin': TextEditingController(), 'audioUrl': TextEditingController(), 'startTime': TextEditingController(), 'endTime': TextEditingController()},
    {'type': 'kasra', 'arabic': TextEditingController(), 'latin': TextEditingController(), 'audioUrl': TextEditingController(), 'startTime': TextEditingController(), 'endTime': TextEditingController()},
    {'type': 'damma', 'arabic': TextEditingController(), 'latin': TextEditingController(), 'audioUrl': TextEditingController(), 'startTime': TextEditingController(), 'endTime': TextEditingController()},
    {'type': 'sukun', 'arabic': TextEditingController(), 'latin': TextEditingController(), 'audioUrl': TextEditingController(), 'startTime': TextEditingController(), 'endTime': TextEditingController()},
  ];
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.letterSound != null) {
      _letterController.text = widget.letterSound!['letter'] as String? ?? '';
      _orderController.text = (widget.letterSound!['order'] as int? ?? 0).toString();
      _selectedDifficulty = widget.letterSound!['difficulty'] as String? ?? 'easy';
      _selectedDifficultyLevel = widget.letterSound!['difficultyLevel'] as int? ?? 1;
      _fullAudioUrlController.text = widget.letterSound!['fullAudioUrl'] as String? ?? '';
      
      final sounds = widget.letterSound!['sounds'] as List<dynamic>? ?? [];
      for (var sound in sounds) {
        final type = sound['type'] as String?;
        final controllerMap = _soundControllers.firstWhere(
          (map) => map['type'] as String == type,
          orElse: () => _soundControllers[0],
        );
        (controllerMap['arabic'] as TextEditingController).text = sound['arabic'] as String? ?? '';
        (controllerMap['latin'] as TextEditingController).text = sound['latin'] as String? ?? '';
        (controllerMap['audioUrl'] as TextEditingController).text = sound['audioUrl'] as String? ?? '';
        (controllerMap['startTime'] as TextEditingController).text = (sound['startTime'] as num? ?? 0).toString();
        (controllerMap['endTime'] as TextEditingController).text = (sound['endTime'] as num? ?? 0).toString();
      }
    }
  }

  @override
  void dispose() {
    _letterController.dispose();
    _orderController.dispose();
    _fullAudioUrlController.dispose();
    for (var map in _soundControllers) {
      (map['arabic'] as TextEditingController).dispose();
      (map['latin'] as TextEditingController).dispose();
      (map['audioUrl'] as TextEditingController).dispose();
      (map['startTime'] as TextEditingController).dispose();
      (map['endTime'] as TextEditingController).dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url) async {
    if (_currentlyPlayingUrl == url && _isPlaying) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _currentlyPlayingUrl = null;
      });
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _isPlaying = true;
        _currentlyPlayingUrl = url;
      });
      
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingUrl = null;
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  Future<void> _saveLetterSound() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final sounds = _soundControllers.map((map) {
      final startTime = double.tryParse((map['startTime'] as TextEditingController).text) ?? 0;
      final endTime = double.tryParse((map['endTime'] as TextEditingController).text) ?? 0;
      return {
        'type': map['type'] as String,
        'arabic': (map['arabic'] as TextEditingController).text.trim(),
        'latin': (map['latin'] as TextEditingController).text.trim(),
        'audioUrl': (map['audioUrl'] as TextEditingController).text.trim(),
        'startTime': startTime,
        'endTime': endTime,
        'duration': endTime > startTime ? endTime - startTime : 0,
      };
    }).toList();

    final data = {
      'letter': _letterController.text.trim(),
      'order': int.tryParse(_orderController.text) ?? 0,
      'difficulty': _selectedDifficulty,
      'difficultyLevel': _selectedDifficultyLevel,
      'fullAudioUrl': _fullAudioUrlController.text.trim(),
      'sounds': sounds,
    };

    final result = widget.letterSound != null
        ? await LetterSoundsService.updateLetterSoundByLetter(
            widget.letterSound!['letter'] as String,
            data,
          )
        : await LetterSoundsService.createLetterSound(data);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.letterSound != null
                ? 'Letter sound updated successfully'
                : 'Letter sound created successfully'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Failed to save letter sound')),
        );
      }
    }
  }

  Widget _buildSoundForm(Map<String, dynamic> soundMap) {
    final type = soundMap['type'] as String;
    final typeLabel = type.toUpperCase();
    final arabicController = soundMap['arabic'] as TextEditingController;
    final latinController = soundMap['latin'] as TextEditingController;
    final audioUrlController = soundMap['audioUrl'] as TextEditingController;
    final startTimeController = soundMap['startTime'] as TextEditingController;
    final endTimeController = soundMap['endTime'] as TextEditingController;
    final audioUrl = audioUrlController.text;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              typeLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: arabicController,
                    decoration: InputDecoration(
                      labelText: 'Arabic ($typeLabel)',
                      hintText: type == 'fatha' ? 'بَ' : type == 'kasra' ? 'بِ' : type == 'damma' ? 'بُ' : 'بْ',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: latinController,
                    decoration: InputDecoration(
                      labelText: 'Latin',
                      hintText: type == 'fatha' ? 'ba' : type == 'kasra' ? 'bi' : type == 'damma' ? 'bu' : 'b',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: audioUrlController,
              decoration: const InputDecoration(
                labelText: 'Audio URL',
                hintText: 'https://res.cloudinary.com/...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'Must be a valid URL';
                }
                return null;
              },
            ),
            if (audioUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying && _currentlyPlayingUrl == audioUrl
                        ? Icons.stop
                        : Icons.play_arrow),
                    onPressed: () => _playAudio(audioUrl),
                  ),
                  const Text('Test Audio'),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: startTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Start Time (seconds)',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final num = double.tryParse(value);
                        if (num == null || num < 0) {
                          return 'Must be >= 0';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: endTimeController,
                    decoration: const InputDecoration(
                      labelText: 'End Time (seconds)',
                      hintText: '2',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final num = double.tryParse(value);
                        if (num == null || num < 0) {
                          return 'Must be >= 0';
                        }
                        final startTime = double.tryParse(startTimeController.text) ?? 0;
                        if (num <= startTime) {
                          return 'Must be > start time';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Row(
        children: [
          Sidebar(currentRoute: '/letter-sounds'),
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
                                    widget.letterSound != null
                                        ? 'Edit Letter Sound'
                                        : 'Create Letter Sound',
                                    style: Theme.of(context).textTheme.displayMedium,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _letterController,
                                          decoration: const InputDecoration(
                                            labelText: 'Letter (Arabic)',
                                            hintText: 'ب',
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Please enter letter';
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
                                            labelText: 'Order',
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Please enter order';
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedDifficulty,
                                          decoration: const InputDecoration(
                                            labelText: 'Difficulty',
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'easy', child: Text('Easy')),
                                            DropdownMenuItem(value: 'medium', child: Text('Medium')),
                                            DropdownMenuItem(value: 'hard', child: Text('Hard')),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedDifficulty = value ?? 'easy';
                                              _selectedDifficultyLevel = value == 'easy' ? 1 : value == 'medium' ? 2 : 3;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
                                          value: _selectedDifficultyLevel,
                                          decoration: const InputDecoration(
                                            labelText: 'Difficulty Level',
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 1, child: Text('Level 1')),
                                            DropdownMenuItem(value: 2, child: Text('Level 2')),
                                            DropdownMenuItem(value: 3, child: Text('Level 3')),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedDifficultyLevel = value ?? 1;
                                              _selectedDifficulty = value == 1 ? 'easy' : value == 2 ? 'medium' : 'hard';
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _fullAudioUrlController,
                                    decoration: const InputDecoration(
                                      labelText: 'Full Audio URL (Optional)',
                                      hintText: 'https://res.cloudinary.com/...',
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Sounds (4 required)',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  ..._soundControllers.map((soundMap) => _buildSoundForm(soundMap)),
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
                                          onPressed: _isLoading ? null : _saveLetterSound,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : Text(widget.letterSound != null ? 'Update' : 'Create'),
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
