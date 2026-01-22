import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';

class StatCard extends StatefulWidget {
  final String title;
  final dynamic value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final String? trend;
  final double? trendValue;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
    this.trendValue,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(dynamic value) {
    if (value is int || value is double) {
      return NumberFormat('#,###').format(value);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        child: Card(
          elevation: _isHovered ? 8 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: widget.color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withOpacity(0.1),
                  widget.color.withOpacity(0.05),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 28,
                      ),
                    ),
                    if (widget.trend != null && widget.trendValue != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.trend == 'up'
                              ? Colors.green.withOpacity(0.2)
                              : widget.trend == 'down'
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.trend == 'up'
                                  ? Icons.trending_up
                                  : widget.trend == 'down'
                                      ? Icons.trending_down
                                      : Icons.trending_flat,
                              size: 14,
                              color: widget.trend == 'up'
                                  ? Colors.green
                                  : widget.trend == 'down'
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${widget.trendValue!.abs().toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: widget.trend == 'up'
                                    ? Colors.green
                                    : widget.trend == 'down'
                                        ? Colors.red
                                        : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FadeTransition(
                    opacity: _animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_animation),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatValue(widget.value),
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: widget.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              widget.title,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.grey700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 3),
                            Flexible(
                              child: Text(
                                widget.subtitle!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.grey600,
                                      fontSize: 11,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
