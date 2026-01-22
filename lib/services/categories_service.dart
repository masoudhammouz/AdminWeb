import '../services/api_service.dart';
import '../utils/api_config.dart';

class CategoriesService {
  // Get all categories
  static Future<Map<String, dynamic>> getAllCategories() async {
    return await ApiService.get(ApiConfig.categoriesUrl);
  }

  // Get category by ID
  static Future<Map<String, dynamic>> getCategoryById(String id) async {
    return await ApiService.get('${ApiConfig.categoriesUrl}/$id');
  }

  // Create category
  static Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    return await ApiService.post(ApiConfig.categoriesUrl, body: data);
  }

  // Update category
  static Future<Map<String, dynamic>> updateCategory(String id, Map<String, dynamic> data) async {
    return await ApiService.put('${ApiConfig.categoriesUrl}/$id', body: data);
  }

  // Toggle category active status
  static Future<Map<String, dynamic>> toggleCategory(String id) async {
    return await ApiService.patch('${ApiConfig.categoriesUrl}/$id/toggle');
  }

  // Delete category
  static Future<Map<String, dynamic>> deleteCategory(String id) async {
    return await ApiService.delete('${ApiConfig.categoriesUrl}/$id');
  }
}
