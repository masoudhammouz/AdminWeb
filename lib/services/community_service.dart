import '../services/api_service.dart';
import '../utils/api_config.dart';

class CommunityService {
  // Get all posts
  static Future<Map<String, dynamic>> getAllPosts({
    bool? reported,
    String? authorId,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (reported != null) queryParams['reported'] = reported.toString();
    if (authorId != null) queryParams['authorId'] = authorId;
    if (search != null) queryParams['search'] = search;

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await ApiService.get('${ApiConfig.communityPostsUrl}?$queryString');
  }

  // Get post by ID
  static Future<Map<String, dynamic>> getPostById(String id) async {
    return await ApiService.get(ApiConfig.communityPostUrl(id));
  }

  // Delete post
  static Future<Map<String, dynamic>> deletePost(String id) async {
    return await ApiService.delete(ApiConfig.communityPostUrl(id));
  }

  // Get all reports
  static Future<Map<String, dynamic>> getAllReports({
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) queryParams['status'] = status;

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await ApiService.get('${ApiConfig.communityReportsUrl}?$queryString');
  }

  // Update report status
  static Future<Map<String, dynamic>> updateReport(String id, String status) async {
    return await ApiService.put(ApiConfig.communityReportUrl(id), body: { 'status': status });
  }

  // Get all comments
  static Future<Map<String, dynamic>> getAllComments({
    String? postId,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (postId != null) queryParams['postId'] = postId;

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await ApiService.get('${ApiConfig.communityCommentsUrl}?$queryString');
  }

  // Delete comment
  static Future<Map<String, dynamic>> deleteComment(String id) async {
    return await ApiService.delete(ApiConfig.communityCommentUrl(id));
  }
}
