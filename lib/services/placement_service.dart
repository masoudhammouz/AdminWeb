import '../services/api_service.dart';
import '../utils/api_config.dart';

class PlacementService {
  // Get all placement questions
  static Future<Map<String, dynamic>> getAll() async {
    return await ApiService.get(ApiConfig.placementQuestionsUrl);
  }

  // Create placement question
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return await ApiService.post(ApiConfig.placementQuestionsUrl, body: data);
  }

  // Update placement question
  static Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    return await ApiService.put(ApiConfig.placementQuestionUrl(id), body: data);
  }

  // Delete placement question
  static Future<Map<String, dynamic>> delete(String id) async {
    return await ApiService.delete(ApiConfig.placementQuestionUrl(id));
  }
}
