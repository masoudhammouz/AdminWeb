import '../services/api_service.dart';
import '../utils/api_config.dart';

class JourneyService {
  // Get all stages
  static Future<Map<String, dynamic>> getAllStages() async {
    return await ApiService.get(ApiConfig.journeyStagesUrl);
  }

  // Create stage
  static Future<Map<String, dynamic>> createStage(Map<String, dynamic> data) async {
    return await ApiService.post(ApiConfig.journeyStagesUrl, body: data);
  }

  // Delete stage by number
  static Future<Map<String, dynamic>> deleteStageByNumber(String level, int stageNumber) async {
    return await ApiService.delete('${ApiConfig.journeyStagesUrl}/by-number?level=$level&stage=$stageNumber');
  }

  // Update stage
  static Future<Map<String, dynamic>> updateStage(String id, Map<String, dynamic> data) async {
    return await ApiService.put('${ApiConfig.journeyStagesUrl}/$id', body: data);
  }

  // Delete stage
  static Future<Map<String, dynamic>> deleteStage(String id) async {
    return await ApiService.delete('${ApiConfig.journeyStagesUrl}/$id');
  }

  // Get all questions
  static Future<Map<String, dynamic>> getAllQuestions({String? level, int? stage}) async {
    final queryParams = <String, String>{};
    if (level != null) queryParams['level'] = level;
    if (stage != null) queryParams['stage'] = stage.toString();

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final url = queryString.isNotEmpty
        ? '${ApiConfig.journeyQuestionsUrl}?$queryString'
        : ApiConfig.journeyQuestionsUrl;

    return await ApiService.get(url);
  }

  // Get question by ID
  static Future<Map<String, dynamic>> getQuestionById(String id) async {
    return await ApiService.get('${ApiConfig.journeyQuestionsUrl}/$id');
  }

  // Create question
  static Future<Map<String, dynamic>> createQuestion(Map<String, dynamic> data) async {
    return await ApiService.post(ApiConfig.journeyQuestionsUrl, body: data);
  }

  // Update question
  static Future<Map<String, dynamic>> updateQuestion(String id, Map<String, dynamic> data) async {
    return await ApiService.put('${ApiConfig.journeyQuestionsUrl}/$id', body: data);
  }

  // Delete question
  static Future<Map<String, dynamic>> deleteQuestion(String id) async {
    return await ApiService.delete('${ApiConfig.journeyQuestionsUrl}/$id');
  }
}
