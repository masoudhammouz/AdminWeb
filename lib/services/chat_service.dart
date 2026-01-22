import '../services/api_service.dart';
import '../utils/api_config.dart';

class ChatService {
  // Get all conversations
  static Future<Map<String, dynamic>> getAllConversations({
    String? status,
    bool? unreadOnly,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (unreadOnly != null) queryParams['unreadOnly'] = unreadOnly.toString();

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final url = queryString.isNotEmpty
        ? '${ApiConfig.chatConversationsUrl}?$queryString'
        : ApiConfig.chatConversationsUrl;

    return await ApiService.get(url);
  }

  // Get conversation by ID
  static Future<Map<String, dynamic>> getConversationById(String id) async {
    return await ApiService.get(ApiConfig.chatConversationUrl(id));
  }

  // Get messages
  static Future<Map<String, dynamic>> getMessages(String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final queryString = 'page=$page&limit=$limit';
    return await ApiService.get('${ApiConfig.chatMessagesUrl(conversationId)}?$queryString');
  }

  // Send message
  static Future<Map<String, dynamic>> sendMessage(String conversationId, String content) async {
    return await ApiService.post(
      ApiConfig.chatMessagesUrl(conversationId),
      body: { 'content': content },
    );
  }

  // Mark as read
  static Future<Map<String, dynamic>> markAsRead(String conversationId) async {
    return await ApiService.put(ApiConfig.chatReadUrl(conversationId));
  }

  // Resolve conversation
  static Future<Map<String, dynamic>> resolveConversation(String conversationId) async {
    return await ApiService.put(ApiConfig.chatResolveUrl(conversationId));
  }

  // Delete conversation
  static Future<Map<String, dynamic>> deleteConversation(String conversationId) async {
    return await ApiService.delete(ApiConfig.chatConversationUrl(conversationId));
  }

  // Get total unread count across all conversations
  static Future<int> getTotalUnreadCount() async {
    try {
      final result = await getAllConversations();
      if (result['success'] == true) {
        final data = result['data'];
        final conversations = data is Map
            ? (data['data'] as List<dynamic>? ?? [])
            : (data is List ? data : []);
        
        int total = 0;
        for (final conv in conversations) {
          final unread = conv['unreadCount'] as int? ?? 0;
          total += unread;
        }
        return total;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
