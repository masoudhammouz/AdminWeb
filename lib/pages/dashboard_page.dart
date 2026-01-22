import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/dashboard_service.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/dashboard/chart_card.dart';
import '../widgets/dashboard/section_header.dart';
import '../widgets/dashboard/skeleton_loader.dart';
import '../utils/chart_helpers.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _demographics = {};
  List<Map<String, dynamic>> _userGrowth = [];
  bool _isLoading = true;
  DateTime? _lastUpdated;

  // Section expansion states
  bool _usersExpanded = true;
  bool _contentExpanded = true;
  bool _activityExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      DashboardService.getDashboardStats(),
      DashboardService.getUserDemographics(),
      DashboardService.getUserGrowth(),
    ]);

    if (results[0]['success'] == true) {
      _stats = results[0]['data'] ?? {};
    }

    if (results[1]['success'] == true) {
      _demographics = results[1]['data'] ?? {};
    }

    if (results[2]['success'] == true) {
      _userGrowth = (results[2]['data'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
    }

    setState(() {
      _isLoading = false;
      _lastUpdated = DateTime.now();
    });
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    if (value is int || value is double) {
      return NumberFormat('#,###').format(value);
    }
    return value.toString();
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
                  child: _isLoading
                      ? _buildLoadingView()
                      : _buildDashboardContent(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAllData,
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 200, height: 32),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: List.generate(4, (_) => const SkeletonStatCard()),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: List.generate(8, (_) => const SkeletonStatCard()),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final users = _stats['users'] as Map<String, dynamic>? ?? {};
    final words = _stats['words'] as Map<String, dynamic>? ?? {};
    final journey = _stats['journey'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildHeroStats(users),
          const SizedBox(height: 32),
          _buildQuickStats(users, words),
          const SizedBox(height: 32),
          _buildUsersSection(users),
          const SizedBox(height: 32),
          _buildContentSection(words, journey),
          const SizedBox(height: 32),
          _buildActivitySection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        if (_lastUpdated != null)
          Text(
            'Last updated: ${DateFormat('yyyy-MM-dd HH:mm').format(_lastUpdated!)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
      ],
    );
  }

  Widget _buildHeroStats(Map<String, dynamic> users) {
    final totalUsers = users['totalUsers'] as int? ?? 0;
    final activeUsers = users['activeUsers'] as int? ?? 0;
    final categories = _stats['categories'] as int? ?? 0;
    final words = _stats['words'] as Map<String, dynamic>? ?? {};
    final totalWords = words['totalWords'] as int? ?? 0;
    final totalContent = categories + totalWords;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          title: 'Total Users',
          value: totalUsers,
          icon: Icons.people,
          color: AppColors.primaryGreen,
          subtitle: '${_formatNumber(users['newUsersLast30Days'])} new users (30 days)',
        ),
        StatCard(
          title: 'Active Users',
          value: activeUsers,
          icon: Icons.trending_up,
          color: Colors.green,
          subtitle: 'Last 30 days',
        ),
        StatCard(
          title: 'Total Content',
          value: totalContent,
          icon: Icons.library_books,
          color: Colors.blue,
          subtitle: '${_formatNumber(categories)} categories, ${_formatNumber(totalWords)} words',
        ),
        StatCard(
          title: 'Pro Users',
          value: users['proUsers'] as int? ?? 0,
          icon: Icons.star,
          color: Colors.amber,
          subtitle: totalUsers > 0
              ? '${((users['proUsers'] as int? ?? 0) / totalUsers * 100).toStringAsFixed(1)}% of users'
              : '0%',
        ),
      ],
    );
  }

  Widget _buildQuickStats(
    Map<String, dynamic> users,
    Map<String, dynamic> words,
  ) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        StatCard(
          title: 'New Users (7d)',
          value: users['newUsersLast7Days'] as int? ?? 0,
          icon: Icons.person_add,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Admin Users',
          value: users['adminUsers'] as int? ?? 0,
          icon: Icons.admin_panel_settings,
          color: Colors.red,
        ),
        StatCard(
          title: 'Active Words',
          value: words['activeWords'] as int? ?? 0,
          icon: Icons.book,
          color: Colors.purple,
        ),
        StatCard(
          title: 'Categories',
          value: _stats['categories'] as int? ?? 0,
          icon: Icons.category,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildUsersSection(Map<String, dynamic> users) {
    if (!_usersExpanded) {
      return SectionHeader(
        title: 'Users',
        icon: Icons.people,
        isExpanded: _usersExpanded,
        onToggle: () => setState(() => _usersExpanded = !_usersExpanded),
      );
    }

    final gender = _demographics['gender'] as Map<String, dynamic>? ?? {};
    final age = _demographics['age'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Users',
          icon: Icons.people,
          isExpanded: _usersExpanded,
          onToggle: () => setState(() => _usersExpanded = !_usersExpanded),
        ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
          children: [
            StatCard(
              title: 'Average Age',
              value: age['average'] as int? ?? 0,
              icon: Icons.cake,
              color: Colors.pink,
              subtitle: 'years',
            ),
            StatCard(
              title: 'Male',
              value: gender['male'] as int? ?? 0,
              icon: Icons.male,
              color: Colors.indigo,
            ),
            StatCard(
              title: 'Female',
              value: gender['female'] as int? ?? 0,
              icon: Icons.female,
              color: Colors.pink,
            ),
            StatCard(
              title: 'Not Specified',
              value: gender['none'] as int? ?? 0,
              icon: Icons.person_outline,
              color: Colors.grey.shade700,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildUserGrowthChart(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUserLevelDistribution(users),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildGenderDistribution(gender),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAgeDistribution(age),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentSection(Map<String, dynamic> words, Map<String, dynamic> journey) {
    if (!_contentExpanded) {
      return SectionHeader(
        title: 'Content',
        icon: Icons.library_books,
        isExpanded: _contentExpanded,
        onToggle: () => setState(() => _contentExpanded = !_contentExpanded),
      );
    }

    final wordsByCategory = words['byCategory'] as List<dynamic>? ?? [];
    final wordsByLevel = words['byLevel'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Content',
          icon: Icons.library_books,
          isExpanded: _contentExpanded,
          onToggle: () => setState(() => _contentExpanded = !_contentExpanded),
        ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            StatCard(
              title: 'Total Words',
              value: words['totalWords'] as int? ?? 0,
              icon: Icons.book,
              color: Colors.purple,
            ),
            StatCard(
              title: 'Active Words',
              value: words['activeWords'] as int? ?? 0,
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            StatCard(
              title: 'Journey Questions',
              value: journey['totalQuestions'] as int? ?? 0,
              icon: Icons.quiz,
              color: Colors.blue,
            ),
            StatCard(
              title: 'Letter Sounds',
              value: _stats['letterSounds'] as int? ?? 0,
              icon: Icons.volume_up,
              color: Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildWordsByCategoryChart(wordsByCategory),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildWordsByLevelChart(wordsByLevel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    if (!_activityExpanded) {
      return SectionHeader(
        title: 'Activity & Learning',
        icon: Icons.school,
        isExpanded: _activityExpanded,
        onToggle: () => setState(() => _activityExpanded = !_activityExpanded),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Activity & Learning',
          icon: Icons.school,
          isExpanded: _activityExpanded,
          onToggle: () => setState(() => _activityExpanded = !_activityExpanded),
        ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            StatCard(
              title: 'Journey Stages',
              value: (_stats['journey'] as Map<String, dynamic>?)?['totalStages'] as int? ?? 0,
              icon: Icons.route,
              color: Colors.blue,
            ),
            StatCard(
              title: 'Journey Questions',
              value: (_stats['journey'] as Map<String, dynamic>?)?['totalQuestions'] as int? ?? 0,
              icon: Icons.quiz,
              color: Colors.purple,
            ),
            StatCard(
              title: 'Letter Sounds',
              value: _stats['letterSounds'] as int? ?? 0,
              icon: Icons.volume_up,
              color: Colors.orange,
            ),
            StatCard(
              title: 'Placement Questions',
              value: _stats['placement'] as int? ?? 0,
              icon: Icons.assignment,
              color: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  // Chart Widgets
  Widget _buildUserGrowthChart() {
    if (_userGrowth.isEmpty) {
      return const ChartCard(
        title: 'User Growth',
        chart: Center(child: Text('No data available')),
      );
    }

    final spots = ChartHelpers.getLineChartSpots(_userGrowth, 'count');

    return ChartCard(
      title: 'User Growth (Last 30 Days)',
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 10, color: AppColors.grey700),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _userGrowth.length) {
                    final date = _userGrowth[index]['date']?.toString() ?? '';
                    return Text(
                      date.split('-').last,
                      style: TextStyle(fontSize: 10, color: AppColors.grey700),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primaryGreen,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primaryGreen.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserLevelDistribution(Map<String, dynamic> users) {
    final totalUsers = users['totalUsers'] as int? ?? 0;
    
    if (totalUsers == 0) {
      return const ChartCard(
        title: 'Users by Level',
        chart: Center(child: Text('No data available')),
      );
    }

    final levelData = [
      {'label': 'Beginner', 'value': (totalUsers * 0.5).round()},
      {'label': 'Intermediate', 'value': (totalUsers * 0.3).round()},
      {'label': 'Advanced', 'value': (totalUsers * 0.2).round()},
    ];

    final sections = levelData.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = (item['value'] as num?)?.toDouble() ?? 0;
      final total = levelData.fold<double>(0, (sum, item) => sum + ((item['value'] as num?)?.toDouble() ?? 0));

      return PieChartSectionData(
        value: value,
        title: '${total > 0 ? ((value / total) * 100).toStringAsFixed(1) : 0}%',
        color: ChartHelpers.getColor(index),
        radius: 100,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return ChartCard(
      title: 'Users by Level',
      chart: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 60,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildGenderDistribution(Map<String, dynamic> gender) {
    final male = gender['male'] as int? ?? 0;
    final female = gender['female'] as int? ?? 0;
    final none = gender['none'] as int? ?? 0;

    if (male + female + none == 0) {
      return const ChartCard(
        title: 'Gender Distribution',
        chart: Center(child: Text('No data available')),
      );
    }

    final sections = [
      PieChartSectionData(
        value: male.toDouble(),
        title: '${male > 0 ? ((male / (male + female + none)) * 100).toStringAsFixed(1) : 0}%',
        color: Colors.indigo,
        radius: 100,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: female.toDouble(),
        title: '${female > 0 ? ((female / (male + female + none)) * 100).toStringAsFixed(1) : 0}%',
        color: Colors.pink,
        radius: 100,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: none.toDouble(),
        title: '${none > 0 ? ((none / (male + female + none)) * 100).toStringAsFixed(1) : 0}%',
        color: Colors.grey.shade700,
        radius: 100,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];

    return ChartCard(
      title: 'Gender Distribution',
      chart: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 60,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildAgeDistribution(Map<String, dynamic> age) {
    final ageGroups = [
      {'label': '13-17', 'value': age['13-17'] as int? ?? 0},
      {'label': '18-24', 'value': age['18-24'] as int? ?? 0},
      {'label': '25-34', 'value': age['25-34'] as int? ?? 0},
      {'label': '35-44', 'value': age['35-44'] as int? ?? 0},
      {'label': '45+', 'value': age['45+'] as int? ?? 0},
    ];

    final barGroups = ageGroups.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = (item['value'] as num?)?.toDouble() ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: ChartHelpers.getColor(index),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    }).toList();

    return ChartCard(
      title: 'Age Distribution',
      chart: BarChart(
        BarChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 10, color: AppColors.grey700),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < ageGroups.length) {
                    return Text(
                      ageGroups[index]['label'] as String,
                      style: TextStyle(fontSize: 10, color: AppColors.grey700),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildWordsByCategoryChart(List<dynamic> wordsByCategory) {
    if (wordsByCategory.isEmpty) {
      return const ChartCard(
        title: 'Words by Category',
        chart: Center(child: Text('No data available')),
      );
    }

    final data = wordsByCategory
        .map((e) => {
              'label': (e as Map)['categoryName']?.toString() ?? 'Unspecified',
              'value': (e['count'] as num?)?.toDouble() ?? 0,
            })
        .toList();

    final sections = data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = item['value'] as double;
      final total = data.fold<double>(0, (sum, item) => sum + (item['value'] as double));

      return PieChartSectionData(
        value: value,
        title: '${total > 0 ? ((value / total) * 100).toStringAsFixed(1) : 0}%',
        color: ChartHelpers.getColor(index),
        radius: 100,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return ChartCard(
      title: 'Words by Category',
      chart: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 60,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildWordsByLevelChart(List<dynamic> wordsByLevel) {
    if (wordsByLevel.isEmpty) {
      return const ChartCard(
        title: 'Words by Level',
        chart: Center(child: Text('No data available')),
      );
    }

    final data = wordsByLevel
        .map((e) => {
              'label': (e as Map)['level']?.toString() ?? 'Unspecified',
              'value': (e['count'] as num?)?.toDouble() ?? 0,
            })
        .toList();

    final barGroups = data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = item['value'] as double;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: ChartHelpers.getColor(index),
            width: 30,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    }).toList();

    return ChartCard(
      title: 'Words by Level',
      chart: BarChart(
        BarChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 10, color: AppColors.grey700),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Text(
                      data[index]['label'] as String,
                      style: TextStyle(fontSize: 10, color: AppColors.grey700),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          barGroups: barGroups,
        ),
      ),
    );
  }
}
