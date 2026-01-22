import 'package:flutter/material.dart';
import '../utils/theme.dart';

class Sidebar extends StatelessWidget {
  final String? currentRoute;
  
  const Sidebar({super.key, this.currentRoute});

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
                  isActive: currentRoute == '/dashboard' || currentRoute == '/',
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                  },
                ),
                _NavItem(
                  icon: Icons.people,
                  label: 'Users',
                  isActive: currentRoute == '/users',
                  onTap: () {
                    Navigator.of(context).pushNamed('/users');
                  },
                ),
                _NavItem(
                  icon: Icons.category,
                  label: 'Categories',
                  isActive: currentRoute == '/categories',
                  onTap: () {
                    Navigator.of(context).pushNamed('/categories');
                  },
                ),
                _NavItem(
                  icon: Icons.book,
                  label: 'Words',
                  isActive: currentRoute == '/words',
                  onTap: () {
                    Navigator.of(context).pushNamed('/words');
                  },
                ),
                _NavItem(
                  icon: Icons.abc,
                  label: 'Letter Sounds',
                  isActive: currentRoute == '/letter-sounds',
                  onTap: () {
                    Navigator.of(context).pushNamed('/letter-sounds');
                  },
                ),
                _NavItem(
                  icon: Icons.route,
                  label: 'Journey',
                  isActive: currentRoute == '/journey',
                  onTap: () {
                    Navigator.of(context).pushNamed('/journey');
                  },
                ),
                _NavItem(
                  icon: Icons.forum,
                  label: 'Community',
                  isActive: currentRoute == '/community',
                  onTap: () {
                    Navigator.of(context).pushNamed('/community');
                  },
                ),
                _NavItem(
                  icon: Icons.chat,
                  label: 'Support Chat',
                  badge: '3',
                  isActive: currentRoute == '/chat',
                  onTap: () {
                    Navigator.of(context).pushNamed('/chat');
                  },
                ),
                _NavItem(
                  icon: Icons.notifications,
                  label: 'Notifications',
                  isActive: currentRoute == '/notifications',
                  onTap: () {
                    Navigator.of(context).pushNamed('/notifications');
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
