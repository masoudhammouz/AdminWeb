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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Letter Sounds',
                              style: Theme.of(context).textTheme.displayMedium,
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
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_letterSounds.isEmpty)
                          Center(
                            child: Text(
                              'No letter sounds found',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: _letterSounds.length,
                            itemBuilder: (context, index) {
                              final letterSound = _letterSounds[index];
                              final letter = letterSound['letter'] as String? ?? '';
                              final order = letterSound['order'] as int? ?? 0;
                              final difficulty = letterSound['difficulty'] as String? ?? '';
                              final id = letterSound['_id'] as String? ?? letterSound['id'] as String? ?? '';
                              return Card(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      letter,
                                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                    ),
                                    Text('Order: $order'),
                                    Text('Difficulty: $difficulty'),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
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
                                          color: AppColors.errorRed,
                                          onPressed: () => _deleteLetterSound(id, letter),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
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
}
