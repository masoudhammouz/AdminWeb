class ApiConfig {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:4000/api';
  
  // Auth endpoints
  static String get loginUrl => '$baseUrl/auth/login';
  static String get meUrl => '$baseUrl/auth/me';
  
  // Admin endpoints
  static String get categoriesUrl => '$baseUrl/v1/admin/categories';
  static String get wordsUrl => '$baseUrl/v1/admin/words';
  static String get letterSoundsUrl => '$baseUrl/admin/letter-sounds';
  static String get journeyStagesUrl => '$baseUrl/journey-exam/admin/stages';
  static String get journeyQuestionsUrl => '$baseUrl/journey-exam/admin/questions';
  static String get notificationsUrl => '$baseUrl/notifications/admin/send';
  static String get audioUploadUrl => '$baseUrl/audio/upload';
  
  // Users management endpoints (to be created)
  static String get usersUrl => '$baseUrl/admin/users';
  static String userUrl(String id) => '$baseUrl/admin/users/$id';
  
  // Community endpoints
  static String get communityPostsUrl => '$baseUrl/admin/community/posts';
  static String get communityReportsUrl => '$baseUrl/admin/community/reports';
  static String get communityCommentsUrl => '$baseUrl/admin/community/comments';
  static String communityPostUrl(String id) => '$baseUrl/admin/community/posts/$id';
  static String communityReportUrl(String id) => '$baseUrl/admin/community/reports/$id';
  static String communityCommentUrl(String id) => '$baseUrl/admin/community/comments/$id';
  
  // Chat endpoints (to be created)
  static String get chatConversationsUrl => '$baseUrl/admin/chat/conversations';
  static String chatConversationUrl(String id) => '$baseUrl/admin/chat/conversations/$id';
  static String chatMessagesUrl(String conversationId) => 
      '$baseUrl/admin/chat/conversations/$conversationId/messages';
  static String chatReadUrl(String conversationId) => 
      '$baseUrl/admin/chat/conversations/$conversationId/read';
  static String chatResolveUrl(String conversationId) => 
      '$baseUrl/admin/chat/conversations/$conversationId/resolve';
}
