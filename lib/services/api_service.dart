import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  // Upload file (multipart/form-data)
  static Future<Map<String, dynamic>> uploadFile(
    String url,
    dynamic file, {
    String fieldName = 'file',
    Map<String, String>? additionalFields,
  }) async {
    try {
      final token = await Storage.getToken();
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add authorization header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Handle file - support both File (mobile) and PlatformFile (web)
      String fileName;
      Uint8List fileBytes;
      
      if (file is Uint8List) {
        // Direct bytes
        fileBytes = file;
        fileName = 'image.png';
      } else {
        // Try to get bytes from file
        try {
          // For web: file should have bytes property
          if (file.bytes != null) {
            fileBytes = file.bytes as Uint8List;
            fileName = file.name ?? 'image.png';
          } else {
            // For mobile: file should be a File object
            final fileStream = (file as dynamic).openRead();
            fileBytes = await fileStream.expand((chunk) => chunk).toList().then((list) => 
              Uint8List.fromList(list.expand((x) => x).toList())
            );
            fileName = (file as dynamic).path.split('/').last;
          }
        } catch (e) {
          return {
            'success': false,
            'error': 'Invalid file format: ${e.toString()}',
          };
        }
      }

      // Add file
      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: fileName,
        contentType: MediaType('image', 'png'),
      );
      request.files.add(multipartFile);

      // Add additional fields if provided
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
          'error': data['message'] as String? ?? 'Upload failed',
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
