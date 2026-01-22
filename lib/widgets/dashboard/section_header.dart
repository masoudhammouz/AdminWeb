import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class SectionHeader extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.isExpanded = true,
    this.onToggle,
    this.action,
  });

  @override
  State<SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<SectionHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              color: AppColors.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (widget.action != null) widget.action!,
          if (widget.onToggle != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                widget.isExpanded
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: AppColors.primaryGreen,
              ),
              onPressed: widget.onToggle,
            ),
          ],
        ],
      ),
    );
  }
}
