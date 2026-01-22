import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/storage.dart';

class ApiService {
  // Get headers with authentication token
  static Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final token = await Storage.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?additionalHeaders,
    };
    return headers;
  }

  // GET request
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(additionalHeaders: headers),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] as String? ?? 'Request failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // POST request
  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(additionalHeaders: headers),
        body: body != null ? jsonEncode(body) : null,
      );

      final responseBody = response.body;
      if (responseBody.isEmpty) {
        return {
          'success': false,
          'error': 'Empty response',
          'statusCode': response.statusCode,
        };
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data.containsKey('success')) {
          return data;
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] as String? ?? 'Request failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // PUT request
  static Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: await _getHeaders(additionalHeaders: headers),
        body: body != null ? jsonEncode(body) : null,
      );

      final responseBody = response.body;
      if (responseBody.isEmpty) {
        return {
          'success': false,
          'error': 'Empty response',
          'statusCode': response.statusCode,
        };
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data.containsKey('success')) {
          return data;
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] as String? ?? 'Request failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // PATCH request
  static Future<Map<String, dynamic>> patch(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: await _getHeaders(additionalHeaders: headers),
        body: body != null ? jsonEncode(body) : null,
      );

      final responseBody = response.body;
      if (responseBody.isEmpty) {
        return {
          'success': false,
          'error': 'Empty response',
          'statusCode': response.statusCode,
        };
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data.containsKey('success')) {
          return data;
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] as String? ?? 'Request failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // DELETE request
  static Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: await _getHeaders(additionalHeaders: headers),
      );

      final responseBody = response.body;
      if (responseBody.isEmpty) {
        return {
          'success': false,
          'error': 'Empty response',
          'statusCode': response.statusCode,
        };
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data.containsKey('success')) {
          return data;
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] as String? ?? 'Request failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
