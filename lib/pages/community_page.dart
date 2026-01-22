import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/community_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _posts = [];
  List<dynamic> _reports = [];
  List<dynamic> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final result = await CommunityService.getAllPosts();
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      setState(() {
        _posts = data?['data'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final result = await CommunityService.getAllReports();
      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          // API returns data as List directly, not nested
          if (data is List) {
            _reports = data;
          } else if (data is Map<String, dynamic>) {
            // Try nested structure first
            _reports = data['data'] as List<dynamic>? ?? [];
            // If still empty, check if data itself is the list
            if (_reports.isEmpty && data.containsKey('reports')) {
              _reports = data['reports'] as List<dynamic>? ?? [];
            }
          } else {
            _reports = [];
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _reports = [];
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] as String? ?? result['message'] as String? ?? 'Failed to load reports'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _reports = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    final result = await CommunityService.getAllComments();
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      setState(() {
        _comments = data?['data'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.beige,
        body: Row(
          children: [
            Sidebar(currentRoute: '/community'),
            Expanded(
              child: Column(
                children: [
                  const app_bar.AppBar(),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
                                tooltip: 'Back to Dashboard',
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Community',
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                            ],
                          ),
                        ),
                        TabBar(
                        controller: _tabController,
                        onTap: (index) {
                          if (index == 0) _loadPosts();
                          if (index == 1) _loadReports();
                          if (index == 2) _loadComments();
                        },
                        tabs: const [
                          Tab(text: 'Posts'),
                          Tab(text: 'Reports'),
                          Tab(text: 'Comments'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPostsTab(),
                            _buildReportsTab(),
                            _buildCommentsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildPostsTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(post['text'] as String? ?? ''),
            subtitle: Text('Author: ${post['author']?['name'] ?? 'Unknown'}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: AppColors.errorRed),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Post'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final result = await CommunityService.deletePost(
                    post['_id'] as String? ?? post['id'] as String? ?? '',
                  );
                  if (result['success'] == true) {
                    _loadPosts();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post deleted successfully')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['error'] as String? ?? 'Failed to delete post')),
                      );
                    }
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No reports found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        try {
          final report = _reports[index];
          if (report == null || report is! Map<String, dynamic>) {
            return const SizedBox.shrink();
          }
        
        final reportId = (report['_id'] as String?) ?? (report['id'] as String?) ?? '';
        final reason = (report['reason'] as String?) ?? 'UNKNOWN';
        final status = (report['status'] as String?) ?? 'OPEN';
        final note = (report['note'] as String?) ?? '';
        
        // Safe date extraction
        String? createdAt;
        final createdAtData = report['createdAt'];
        if (createdAtData != null) {
          if (createdAtData is String) {
            createdAt = createdAtData;
          } else {
            createdAt = createdAtData.toString();
          }
        }
        
        String? updatedAt;
        final updatedAtData = report['updatedAt'];
        if (updatedAtData != null) {
          if (updatedAtData is String) {
            updatedAt = updatedAtData;
          } else {
            updatedAt = updatedAtData.toString();
          }
        }
        
        // Reporter info
        final reporterData = report['reporter'];
        Map<String, dynamic>? reporter;
        if (reporterData is Map<String, dynamic>) {
          reporter = reporterData;
        }
        final reporterName = (reporter?['name'] as String?) ?? 'Unknown';
        final reporterEmail = (reporter?['email'] as String?) ?? '';
        
        // Reported user info
        final reportedUserData = report['reportedUser'];
        Map<String, dynamic>? reportedUser;
        if (reportedUserData is Map<String, dynamic>) {
          reportedUser = reportedUserData;
        }
        final reportedUserName = (reportedUser?['name'] as String?) ?? 'Unknown';
        final reportedUserEmail = (reportedUser?['email'] as String?) ?? '';
        
        // Safe values for reported user
        final safeReportedUserName = reportedUserName.isNotEmpty ? reportedUserName : 'Unknown';
        final safeReportedUserEmail = reportedUserEmail.isNotEmpty ? reportedUserEmail : 'N/A';
        
        // Post info
        final post = report['post'];
        Map<String, dynamic>? postMap;
        if (post is Map<String, dynamic>) {
          postMap = post;
        } else if (post != null) {
          // Handle case where post might be just an ID string
          postMap = null;
        }
        final postId = (postMap?['_id'] as String?) ?? (postMap?['id'] as String?) ?? '';
        final postText = (postMap?['text'] as String?) ?? '';
        
        // Safe post image URL extraction
        String? postImageUrl;
        final postImageUrlData = postMap?['imageUrl'];
        if (postImageUrlData != null) {
          if (postImageUrlData is String) {
            postImageUrl = postImageUrlData;
          } else {
            postImageUrl = postImageUrlData.toString();
          }
        }
        
        // Safe post created at extraction
        String? postCreatedAt;
        final postCreatedAtData = postMap?['createdAt'];
        if (postCreatedAtData != null) {
          if (postCreatedAtData is String) {
            postCreatedAt = postCreatedAtData;
          } else {
            postCreatedAt = postCreatedAtData.toString();
          }
        }
        
        final postLikeCount = (postMap?['likeCount'] as int?) ?? 0;
        final postCommentCount = (postMap?['commentCount'] as int?) ?? 0;

        // Status color
        Color statusColor;
        IconData statusIcon;
        switch (status) {
          case 'OPEN':
            statusColor = Colors.orange;
            statusIcon = Icons.warning;
            break;
          case 'REVIEWED':
            statusColor = Colors.blue;
            statusIcon = Icons.visibility;
            break;
          case 'DISMISSED':
            statusColor = Colors.grey;
            statusIcon = Icons.cancel;
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.help;
        }

        // Reason color
        Color reasonColor;
        IconData reasonIcon;
        switch (reason) {
          case 'SPAM':
            reasonColor = Colors.red;
            reasonIcon = Icons.block;
            break;
          case 'OFFENSIVE':
            reasonColor = Colors.deepOrange;
            reasonIcon = Icons.report_problem;
            break;
          case 'INAPPROPRIATE':
            reasonColor = Colors.orange;
            reasonIcon = Icons.warning;
            break;
          case 'OTHER':
            reasonColor = Colors.grey;
            reasonIcon = Icons.info;
            break;
          default:
            reasonColor = Colors.grey;
            reasonIcon = Icons.help;
        }

        String _formatDate(String? dateStr) {
          if (dateStr == null || dateStr.isEmpty) return 'N/A';
          try {
            final date = DateTime.parse(dateStr);
            return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
          } catch (e) {
            return dateStr;
          }
        }

        // Ensure all required values are not null
        final safeReason = reason.isNotEmpty ? reason : 'UNKNOWN';
        final safeStatus = status.isNotEmpty ? status : 'OPEN';
        final safeReporterName = reporterName.isNotEmpty ? reporterName : 'Unknown';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: ExpansionTile(
            initiallyExpanded: safeStatus == 'OPEN',
            leading: Icon(reasonIcon, color: reasonColor),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        safeReason,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reported by: $safeReporterName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        safeStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report Details Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Reason', safeReason, icon: reasonIcon, color: reasonColor),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow('Note', note),
                          ],
                          const SizedBox(height: 8),
                          _buildInfoRow('Reported At', _formatDate(createdAt)),
                          if (updatedAt != createdAt)
                            _buildInfoRow('Last Updated', _formatDate(updatedAt)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Reporter Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 18, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Reporter',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('Name', safeReporterName),
                          _buildInfoRow('Email', reporterEmail.isNotEmpty ? reporterEmail : 'N/A'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Reported User Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_off, size: 18, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Reported User',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('Name', safeReportedUserName),
                          _buildInfoRow('Email', safeReportedUserEmail),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Post Section
                    if (postMap != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.post_add, size: 18, color: Colors.green.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Reported Post',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (postText.isNotEmpty)
                              _buildInfoRow('Text', postText, maxLines: 3),
                            if (postId.isNotEmpty)
                              _buildInfoRow('Post ID', postId.length > 20 ? '${postId.substring(0, 20)}...' : postId),
                            _buildInfoRow('Created At', _formatDate(postCreatedAt)),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            'Likes:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            postLikeCount.toString(),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            'Comments:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            postCommentCount.toString(),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (postImageUrl != null && postImageUrl.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Image:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  postImageUrl,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: Icon(Icons.broken_image),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Actions Section
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: safeStatus,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: [
                                DropdownMenuItem(
                                  value: 'OPEN',
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning, size: 18, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      const Text('OPEN'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'REVIEWED',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility, size: 18, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      const Text('REVIEWED'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'DISMISSED',
                                  child: Row(
                                    children: [
                                      Icon(Icons.cancel, size: 18, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      const Text('DISMISSED'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) async {
                                if (value != null && value != safeStatus && reportId.isNotEmpty) {
                                  final result = await CommunityService.updateReport(
                                    reportId,
                                    value,
                                  );
                                  if (result['success'] == true) {
                                    _loadReports();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Report status updated to $value'),
                                          backgroundColor: AppColors.primaryGreen,
                                        ),
                                      );
                                    }
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(result['error'] as String? ?? 'Failed to update report'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (postId.isNotEmpty && postMap != null)
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.errorRed),
                            tooltip: 'Delete Post',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Post'),
                                  content: const Text('Are you sure you want to delete this reported post?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && postId.isNotEmpty) {
                                final result = await CommunityService.deletePost(postId);
                                if (result['success'] == true) {
                                  _loadReports();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Post deleted successfully'),
                                        backgroundColor: AppColors.primaryGreen,
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['error'] as String? ?? 'Failed to delete post'),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        } catch (e) {
          // Return error widget if there's an error building the report card
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error loading report',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildInfoRow(String label, String? value, {IconData? icon, Color? color, int? maxLines}) {
    final safeValue = value ?? 'N/A';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color ?? Colors.grey),
          const SizedBox(width: 6),
        ],
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            safeValue,
            style: const TextStyle(fontSize: 12),
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(comment['text'] as String? ?? ''),
            subtitle: Text('User: ${comment['user']?['name'] ?? 'Unknown'}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: AppColors.errorRed),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Comment'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final result = await CommunityService.deleteComment(
                    comment['_id'] as String? ?? comment['id'] as String? ?? '',
                  );
                  if (result['success'] == true) {
                    _loadComments();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comment deleted successfully')),
                      );
                    }
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }
}
