import '../services/api_service.dart';
import '../utils/api_config.dart';

class UsersService {
  // Get all users
  static Future<Map<String, dynamic>> getAllUsers({
    String? role,
    bool? isPro,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (role != null) queryParams['role'] = role;
    if (isPro != null) queryParams['isPro'] = isPro.toString();
    if (search != null) queryParams['search'] = search;

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await ApiService.get('${ApiConfig.usersUrl}?$queryString');
  }

  // Get user by ID
  static Future<Map<String, dynamic>> getUserById(String id) async {
    return await ApiService.get(ApiConfig.userUrl(id));
  }

  // Update user
  static Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data) async {
    return await ApiService.put(ApiConfig.userUrl(id), body: data);
  }

  // Delete user
  static Future<Map<String, dynamic>> deleteUser(String id) async {
    return await ApiService.delete(ApiConfig.userUrl(id));
  }

  // Get user statistics
  static Future<Map<String, dynamic>> getUserStats() async {
    return await ApiService.get('${ApiConfig.usersUrl}/stats');
  }
}
