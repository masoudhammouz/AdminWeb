import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/users_service.dart';
import '../services/categories_service.dart';
import '../services/words_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'proUsers': 0,
    'adminUsers': 0,
    'activeUsers': 0,
    'newUsersLast7Days': 0,
    'newUsersLast30Days': 0,
    'categories': 0,
    'words': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      UsersService.getUserStats(),
      CategoriesService.getAllCategories(),
      WordsService.getWordsStats(),
    ]);

    if (results[0]['success'] == true) {
      final responseData = results[0]['data'] as Map<String, dynamic>?;
      // API returns { success: true, data: { totalUsers, ... } }
      final userStatsData = responseData?['data'] as Map<String, dynamic>? ?? responseData;
      if (userStatsData != null && userStatsData is Map) {
        _stats['totalUsers'] = userStatsData['totalUsers'] as int? ?? 0;
        _stats['proUsers'] = userStatsData['proUsers'] as int? ?? 0;
        _stats['adminUsers'] = userStatsData['adminUsers'] as int? ?? 0;
        _stats['activeUsers'] = userStatsData['activeUsers'] as int? ?? 0;
        _stats['newUsersLast7Days'] = userStatsData['newUsersLast7Days'] as int? ?? 0;
        _stats['newUsersLast30Days'] = userStatsData['newUsersLast30Days'] as int? ?? 0;
      }
    }

    if (results[1]['success'] == true) {
      final categoriesData = results[1]['data'];
      if (categoriesData is Map) {
        final categories = categoriesData['data'] as List<dynamic>? ?? [];
        _stats['categories'] = categories.length;
      } else if (categoriesData is List) {
        _stats['categories'] = categoriesData.length;
      }
    }

    if (results[2]['success'] == true) {
      final raw = results[2]['data'];
      final wordStatsData = raw is Map ? (raw['data'] as Map? ?? raw) : null;
      if (wordStatsData is Map) {
        _stats['words'] = wordStatsData['totalWords'] as int? ??
            wordStatsData['total'] as int? ??
            wordStatsData['words'] as int? ??
            wordStatsData['count'] as int? ??
            0;
      } else if (raw is Map && raw['totalWords'] != null) {
        _stats['words'] = raw['totalWords'] as int? ?? 0;
      }
    }
    if ((_stats['words'] as int) == 0) {
      final wordsRes = await WordsService.getAllWords(limit: 1, page: 1);
      if (wordsRes['success'] == true) {
        final d = wordsRes['data'] as Map<String, dynamic>?;
        final p = d?['pagination'] as Map<String, dynamic>?;
        final total = p?['total'] as int?;
        if (total != null && total > 0) {
          _stats['words'] = total;
        }
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Row(
        children: [
          Sidebar(currentRoute: '/dashboard'),
          Expanded(
            child: Column(
              children: [
                const app_bar.AppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 24),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          Column(
                            children: [
                              // First row - Main stats
                              GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.5,
                                children: [
                                  _StatCard(
                                    title: 'Total Users',
                                    value: _stats['totalUsers'].toString(),
                                    icon: Icons.people,
                                    color: AppColors.primaryGreen,
                                  ),
                                  _StatCard(
                                    title: 'Pro Users',
                                    value: _stats['totalUsers'] > 0
                                        ? '${_stats['proUsers']} (${(((_stats['proUsers'] as int) / (_stats['totalUsers'] as int)) * 100).toStringAsFixed(1)}%)'
                                        : _stats['proUsers'].toString(),
                                    icon: Icons.star,
                                    color: Colors.amber,
                                  ),
                                  _StatCard(
                                    title: 'Categories',
                                    value: _stats['categories'].toString(),
                                    icon: Icons.category,
                                    color: Colors.blue,
                                  ),
                                  _StatCard(
                                    title: 'Words',
                                    value: _stats['words'].toString(),
                                    icon: Icons.book,
                                    color: Colors.purple,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Second row - User stats
                              GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.5,
                                children: [
                                  _StatCard(
                                    title: 'Admin Users',
                                    value: _stats['adminUsers'].toString(),
                                    icon: Icons.admin_panel_settings,
                                    color: Colors.red,
                                  ),
                                  _StatCard(
                                    title: 'Active Users (30d)',
                                    value: _stats['activeUsers'].toString(),
                                    icon: Icons.trending_up,
                                    color: Colors.green,
                                  ),
                                  _StatCard(
                                    title: 'New Users (7d)',
                                    value: _stats['newUsersLast7Days'].toString(),
                                    icon: Icons.person_add,
                                    color: Colors.orange,
                                  ),
                                  _StatCard(
                                    title: 'New Users (30d)',
                                    value: _stats['newUsersLast30Days'].toString(),
                                    icon: Icons.people_outline,
                                    color: Colors.teal,
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
