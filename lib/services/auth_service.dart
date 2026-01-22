import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/storage.dart';

class AuthService {
  // Login with email and password
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Check if user is admin
        final user = data['user'] as Map<String, dynamic>;
        final role = user['role'] as String?;
        
        if (role != 'admin') {
          throw Exception('Access denied. Admin role required.');
        }

        // Save token and user data
        final token = data['token'] as String;
        await Storage.saveToken(token);
        await Storage.saveUser(user);

        return {
          'success': true,
          'token': token,
          'user': user,
        };
      } else {
        final message = data['message'] as String? ?? 'Login failed';
        throw Exception(message);
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  // Get current user info
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await Storage.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse(ApiConfig.meUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;
        
        // Check if user is admin
        final role = user['role'] as String?;
        if (role != 'admin') {
          await logout();
          return null;
        }

        await Storage.saveUser(user);
        return user;
      } else {
        await logout();
        return null;
      }
    } catch (e) {
      await logout();
      return null;
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await Storage.getToken();
    if (token == null) return false;

    // Verify token is still valid
    final user = await getCurrentUser();
    return user != null;
  }

  // Logout
  static Future<void> logout() async {
    await Storage.clearAll();
  }

  // Get stored token
  static Future<String?> getToken() async {
    return await Storage.getToken();
  }

  // Get stored user
  static Future<Map<String, dynamic>?> getStoredUser() async {
    return await Storage.getUser();
  }
}
