import '../services/api_service.dart';
import '../utils/api_config.dart';
import 'users_service.dart';
import 'categories_service.dart';
import 'words_service.dart';
import 'community_service.dart';
import 'chat_service.dart';
import 'journey_service.dart';
import 'placement_service.dart';
import 'letter_sounds_service.dart';

class DashboardService {
  // Get comprehensive dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final results = await Future.wait([
        UsersService.getUserStats(),
        CategoriesService.getAllCategories(),
        WordsService.getWordsStats(),
        CommunityService.getAllPosts(page: 1, limit: 1),
        CommunityService.getAllComments(page: 1, limit: 1),
        CommunityService.getAllReports(page: 1, limit: 1),
        ChatService.getAllConversations(),
        JourneyService.getAllQuestions(),
        JourneyService.getAllStages(),
        PlacementService.getAll(),
        LetterSoundsService.getAllLetterSounds(),
      ]);

      // Process user stats
      Map<String, dynamic> userStats = {};
      if (results[0]['success'] == true) {
        final responseData = results[0]['data'] as Map<String, dynamic>?;
        final userStatsData = responseData?['data'] as Map<String, dynamic>? ?? responseData;
        if (userStatsData != null && userStatsData is Map) {
          userStats = {
            'totalUsers': userStatsData['totalUsers'] as int? ?? 0,
            'proUsers': userStatsData['proUsers'] as int? ?? 0,
            'adminUsers': userStatsData['adminUsers'] as int? ?? 0,
            'activeUsers': userStatsData['activeUsers'] as int? ?? 0,
            'newUsersLast7Days': userStatsData['newUsersLast7Days'] as int? ?? 0,
            'newUsersLast30Days': userStatsData['newUsersLast30Days'] as int? ?? 0,
          };
        }
      }

      // Process categories
      int categoriesCount = 0;
      if (results[1]['success'] == true) {
        final categoriesData = results[1]['data'];
        if (categoriesData is Map) {
          final categories = categoriesData['data'] as List<dynamic>? ?? [];
          categoriesCount = categories.length;
        } else if (categoriesData is List) {
          categoriesCount = categoriesData.length;
        }
      }

      // Process words stats
      Map<String, dynamic> wordsStats = {};
      if (results[2]['success'] == true) {
        final raw = results[2]['data'];
        final wordStatsData = raw is Map ? (raw['data'] as Map? ?? raw) : null;
        if (wordStatsData is Map) {
          wordsStats = {
            'totalWords': wordStatsData['totalWords'] as int? ??
                wordStatsData['total'] as int? ??
                wordStatsData['words'] as int? ??
                wordStatsData['count'] as int? ??
                0,
            'activeWords': wordStatsData['activeWords'] as int? ?? 0,
            'inactiveWords': wordStatsData['inactiveWords'] as int? ?? 0,
            'byCategory': wordStatsData['byCategory'] as List<dynamic>? ?? [],
            'byLevel': wordStatsData['byLevel'] as List<dynamic>? ?? [],
          };
        }
      }

      // Process community stats
      Map<String, dynamic> communityStats = {};
      if (results[3]['success'] == true) {
        final postsData = results[3]['data'];
        if (postsData is Map) {
          final pagination = postsData['pagination'] as Map<String, dynamic>?;
          communityStats['totalPosts'] = pagination?['total'] as int? ?? 0;
        }
      }

      if (results[4]['success'] == true) {
        final commentsData = results[4]['data'];
        if (commentsData is Map) {
          final pagination = commentsData['pagination'] as Map<String, dynamic>?;
          communityStats['totalComments'] = pagination?['total'] as int? ?? 0;
        }
      }

      if (results[5]['success'] == true) {
        final reportsData = results[5]['data'];
        if (reportsData is Map) {
          final pagination = reportsData['pagination'] as Map<String, dynamic>?;
          communityStats['totalReports'] = pagination?['total'] as int? ?? 0;
        }
      }

      // Process chat stats
      Map<String, dynamic> chatStats = {};
      if (results[6]['success'] == true) {
        final conversationsData = results[6]['data'];
        if (conversationsData is List) {
          final conversations = conversationsData;
          chatStats['totalConversations'] = conversations.length;
          chatStats['openConversations'] = conversations.where((c) => c['status'] == 'open').length;
          chatStats['resolvedConversations'] = conversations.where((c) => c['status'] == 'resolved').length;
          chatStats['closedConversations'] = conversations.where((c) => c['status'] == 'closed').length;
        } else if (conversationsData is Map) {
          final data = conversationsData['data'] as List<dynamic>? ?? [];
          chatStats['totalConversations'] = data.length;
          chatStats['openConversations'] = data.where((c) => (c as Map)['status'] == 'open').length;
          chatStats['resolvedConversations'] = data.where((c) => (c as Map)['status'] == 'resolved').length;
          chatStats['closedConversations'] = data.where((c) => (c as Map)['status'] == 'closed').length;
        }
      }

      // Process journey stats
      Map<String, dynamic> journeyStats = {};
      if (results[7]['success'] == true) {
        final questionsData = results[7]['data'];
        if (questionsData is List) {
          journeyStats['totalQuestions'] = questionsData.length;
        } else if (questionsData is Map) {
          final data = questionsData['data'] as List<dynamic>? ?? [];
          journeyStats['totalQuestions'] = data.length;
        }
      }

      if (results[8]['success'] == true) {
        final stagesData = results[8]['data'];
        if (stagesData is List) {
          journeyStats['totalStages'] = stagesData.length;
        } else if (stagesData is Map) {
          final data = stagesData['data'] as List<dynamic>? ?? [];
          journeyStats['totalStages'] = data.length;
        }
      }

      // Process placement stats
      int placementQuestions = 0;
      if (results[9]['success'] == true) {
        final placementData = results[9]['data'];
        if (placementData is List) {
          placementQuestions = placementData.length;
        } else if (placementData is Map) {
          final data = placementData['data'] as List<dynamic>? ?? [];
          placementQuestions = data.length;
        }
      }

      // Process letter sounds stats
      int letterSounds = 0;
      if (results[10]['success'] == true) {
        final letterSoundsData = results[10]['data'];
        if (letterSoundsData is List) {
          letterSounds = letterSoundsData.length;
        } else if (letterSoundsData is Map) {
          final data = letterSoundsData['data'] as List<dynamic>? ?? [];
          letterSounds = data.length;
        }
      }

      return {
        'success': true,
        'data': {
          'users': userStats,
          'categories': categoriesCount,
          'words': wordsStats,
          'community': communityStats,
          'chat': chatStats,
          'journey': journeyStats,
          'placement': placementQuestions,
          'letterSounds': letterSounds,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get user demographics
  static Future<Map<String, dynamic>> getUserDemographics() async {
    try {
      // Get all users to calculate demographics
      final usersResult = await UsersService.getAllUsers(limit: 1000);
      
      if (usersResult['success'] != true) {
        return {
          'success': false,
          'error': 'Failed to fetch users',
        };
      }

      final usersData = usersResult['data'];
      List<dynamic> users = [];
      
      if (usersData is Map) {
        users = usersData['data'] as List<dynamic>? ?? [];
      } else if (usersData is List) {
        users = usersData;
      }

      // Calculate gender distribution
      int maleCount = 0;
      int femaleCount = 0;
      int noneCount = 0;
      
      // Calculate age distribution
      final now = DateTime.now();
      int age13to17 = 0;
      int age18to24 = 0;
      int age25to34 = 0;
      int age35to44 = 0;
      int age45plus = 0;
      int totalAge = 0;
      int validAges = 0;

      for (final user in users) {
        if (user is Map) {
          // Gender
          final gender = user['gender'] as String?;
          if (gender == 'Male') {
            maleCount++;
          } else if (gender == 'Female') {
            femaleCount++;
          } else {
            noneCount++;
          }

          // Age
          final dateOfBirth = user['dateOfBirth'];
          if (dateOfBirth != null) {
            DateTime? birthDate;
            if (dateOfBirth is String) {
              birthDate = DateTime.tryParse(dateOfBirth);
            } else if (dateOfBirth is Map && dateOfBirth['\$date'] != null) {
              final timestamp = dateOfBirth['\$date'] as int?;
              if (timestamp != null) {
                birthDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
              }
            }

            if (birthDate != null) {
              int age = now.year - birthDate.year;
              if (now.month < birthDate.month || 
                  (now.month == birthDate.month && now.day < birthDate.day)) {
                age--;
              }

              totalAge += age;
              validAges++;

              if (age >= 13 && age <= 17) {
                age13to17++;
              } else if (age >= 18 && age <= 24) {
                age18to24++;
              } else if (age >= 25 && age <= 34) {
                age25to34++;
              } else if (age >= 35 && age <= 44) {
                age35to44++;
              } else if (age >= 45) {
                age45plus++;
              }
            }
          }
        }
      }

      final averageAge = validAges > 0 ? (totalAge / validAges).round() : 0;

      return {
        'success': true,
        'data': {
          'gender': {
            'male': maleCount,
            'female': femaleCount,
            'none': noneCount,
            'total': users.length,
          },
          'age': {
            '13-17': age13to17,
            '18-24': age18to24,
            '25-34': age25to34,
            '35-44': age35to44,
            '45+': age45plus,
            'average': averageAge,
            'total': validAges,
          },
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get user growth data (last 30 days)
  static Future<Map<String, dynamic>> getUserGrowth() async {
    try {
      // Get all users
      final usersResult = await UsersService.getAllUsers(limit: 10000);
      
      if (usersResult['success'] != true) {
        return {
          'success': false,
          'error': 'Failed to fetch users',
        };
      }

      final usersData = usersResult['data'];
      List<dynamic> users = [];
      
      if (usersData is Map) {
        users = usersData['data'] as List<dynamic>? ?? [];
      } else if (usersData is List) {
        users = usersData;
      }

      // Group by date (last 30 days)
      final now = DateTime.now();
      final Map<String, int> dailyGrowth = {};
      
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyGrowth[dateKey] = 0;
      }

      for (final user in users) {
        if (user is Map) {
          final createdAt = user['createdAt'];
          if (createdAt != null) {
            DateTime? createdDate;
            if (createdAt is String) {
              createdDate = DateTime.tryParse(createdAt);
            } else if (createdAt is Map && createdAt['\$date'] != null) {
              final timestamp = createdAt['\$date'] as int?;
              if (timestamp != null) {
                createdDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
              }
            }

            if (createdDate != null) {
              final dateKey = '${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}';
              if (dailyGrowth.containsKey(dateKey)) {
                dailyGrowth[dateKey] = (dailyGrowth[dateKey] ?? 0) + 1;
              }
            }
          }
        }
      }

      // Convert to list format
      final growthData = dailyGrowth.entries.map((e) => {
        'date': e.key,
        'count': e.value,
      }).toList();

      return {
        'success': true,
        'data': growthData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
