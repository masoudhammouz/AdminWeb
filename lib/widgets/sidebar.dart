import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/chat_service.dart';

class Sidebar extends StatefulWidget {
  final String? currentRoute;
  
  const Sidebar({super.key, this.currentRoute});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  int _unreadCount = 0;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _loadUnreadCount();
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await ChatService.getTotalUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  String? _getBadgeText() {
    if (_unreadCount <= 0) return null;
    if (_unreadCount < 10) return _unreadCount.toString();
    return '+9';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.white,
      child: Column(
        children: [
          // Logo/Title
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.primaryGreen,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Admin Panel',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isActive: widget.currentRoute == '/dashboard' || widget.currentRoute == '/',
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed('/dashboard');
                  },
                ),
                _NavItem(
                  icon: Icons.people,
                  label: 'Users',
                  isActive: widget.currentRoute == '/users',
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed('/users');
                  },
                ),
                _NavItem(
                  icon: Icons.category,
                  label: 'Categories',
                  isActive: widget.currentRoute == '/categories',
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed('/categories');
                  },
                ),
                _NavItem(
                  icon: Icons.abc,
                  label: 'Letter Sounds',
                  isActive: widget.currentRoute == '/letter-sounds',
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed('/letter-sounds');
                  },
                ),
                _NavItem(
                  icon: Icons.route,
                  label: 'Journey',
                  isActive: widget.currentRoute == '/journey',
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed('/journey');
                  },
                ),
                _NavItem(
                  icon: Icons.forum,
                  label: 'Community',
                  isActive: widget.currentRoute == '/community',
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed('/community');
                  },
                ),
                _NavItem(
                  icon: Icons.chat,
                  label: 'Support Chat',
                  badge: _getBadgeText(),
                  isActive: widget.currentRoute == '/chat',
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed('/chat');
                  },
                ),
                _NavItem(
                  icon: Icons.notifications,
                  label: 'Notifications',
                  isActive: widget.currentRoute == '/notifications',
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed('/notifications');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.badge,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isActive ? AppColors.primaryGreen.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primaryGreen : AppColors.grey700,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primaryGreen : null,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
        hoverColor: AppColors.grey100,
      ),
    );
  }
}
