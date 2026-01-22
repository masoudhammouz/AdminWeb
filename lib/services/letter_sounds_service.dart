import '../services/api_service.dart';
import '../utils/api_config.dart';

class LetterSoundsService {
  // Get all letter sounds
  static Future<Map<String, dynamic>> getAllLetterSounds() async {
    return await ApiService.get(ApiConfig.letterSoundsUrl);
  }

  // Get letter sound by ID
  static Future<Map<String, dynamic>> getLetterSoundById(String id) async {
    return await ApiService.get('${ApiConfig.letterSoundsUrl}/$id');
  }

  // Get letter sound by letter
  static Future<Map<String, dynamic>> getLetterSoundByLetter(String letter) async {
    return await ApiService.get('${ApiConfig.letterSoundsUrl}/letter/$letter');
  }

  // Create letter sound
  static Future<Map<String, dynamic>> createLetterSound(Map<String, dynamic> data) async {
    return await ApiService.post(ApiConfig.letterSoundsUrl, body: data);
  }

  // Update letter sound by ID
  static Future<Map<String, dynamic>> updateLetterSound(String id, Map<String, dynamic> data) async {
    return await ApiService.put('${ApiConfig.letterSoundsUrl}/$id', body: data);
  }

  // Update letter sound by letter
  static Future<Map<String, dynamic>> updateLetterSoundByLetter(String letter, Map<String, dynamic> data) async {
    return await ApiService.put('${ApiConfig.letterSoundsUrl}/letter/$letter', body: data);
  }

  // Delete letter sound by ID
  static Future<Map<String, dynamic>> deleteLetterSound(String id) async {
    return await ApiService.delete('${ApiConfig.letterSoundsUrl}/$id');
  }

  // Delete letter sound by letter
  static Future<Map<String, dynamic>> deleteLetterSoundByLetter(String letter) async {
    return await ApiService.delete('${ApiConfig.letterSoundsUrl}/letter/$letter');
  }

  // Update sound timestamps
  static Future<Map<String, dynamic>> updateSoundTimestamps(
    String id,
    String soundType,
    Map<String, dynamic> timestamps,
  ) async {
    return await ApiService.put(
      '${ApiConfig.letterSoundsUrl}/$id/sounds/$soundType',
      body: timestamps,
    );
  }
}
