import '../services/api_service.dart';
import '../utils/api_config.dart';

class WordsService {
  // Get all words
  static Future<Map<String, dynamic>> getAllWords({
    String? category,
    String? level,
    bool? isActive,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null) queryParams['category'] = category;
    if (level != null) queryParams['level'] = level;
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    if (search != null) queryParams['search'] = search;

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await ApiService.get('${ApiConfig.wordsUrl}?$queryString');
  }

  // Get word by ID
  static Future<Map<String, dynamic>> getWordById(String id) async {
    return await ApiService.get('${ApiConfig.wordsUrl}/$id');
  }

  // Create word
  static Future<Map<String, dynamic>> createWord(Map<String, dynamic> data) async {
    return await ApiService.post(ApiConfig.wordsUrl, body: data);
  }

  // Update word
  static Future<Map<String, dynamic>> updateWord(String id, Map<String, dynamic> data) async {
    return await ApiService.put('${ApiConfig.wordsUrl}/$id', body: data);
  }

  // Delete word
  static Future<Map<String, dynamic>> deleteWord(String id) async {
    return await ApiService.delete('${ApiConfig.wordsUrl}/$id');
  }

  // Bulk create words
  static Future<Map<String, dynamic>> bulkCreateWords(List<Map<String, dynamic>> words) async {
    return await ApiService.post('${ApiConfig.wordsUrl}/bulk', body: { 'words': words });
  }

  // Get words statistics
  static Future<Map<String, dynamic>> getWordsStats() async {
    return await ApiService.get('${ApiConfig.wordsUrl}/stats');
  }
}
