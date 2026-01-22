import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'theme.dart';

class ChartHelpers {
  // Color palette for charts
  static const List<Color> chartColors = [
    AppColors.primaryGreen,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
  ];

  static Color getColor(int index) {
    return chartColors[index % chartColors.length];
  }

  // Pie chart sections
  static List<PieChartSectionData> getPieChartSections(
    List<Map<String, dynamic>> data,
    String labelKey,
    String valueKey,
  ) {
    final total = data.fold<double>(
      0,
      (sum, item) => sum + ((item[valueKey] as num?)?.toDouble() ?? 0),
    );

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = (item[valueKey] as num?)?.toDouble() ?? 0;
      final percentage = total > 0 ? (value / total * 100) : 0;

      return PieChartSectionData(
        value: value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: getColor(index),
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Bar chart groups
  static List<BarChartGroupData> getBarChartGroups(
    List<Map<String, dynamic>> data,
    String valueKey,
    double barWidth,
  ) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = (item[valueKey] as num?)?.toDouble() ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: getColor(index),
            width: barWidth,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
        ],
      );
    }).toList();
  }

  // Line chart spots
  static List<FlSpot> getLineChartSpots(
    List<Map<String, dynamic>> data,
    String valueKey,
  ) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = (item[valueKey] as num?)?.toDouble() ?? 0;

      return FlSpot(index.toDouble(), value);
    }).toList();
  }

  // Side titles for bar charts
  static SideTitles getBarChartSideTitles(
    List<Map<String, dynamic>> data,
    String labelKey,
  ) {
    return SideTitles(
      showTitles: true,
      getTitlesWidget: (value, meta) {
        final index = value.toInt();
        if (index >= 0 && index < data.length) {
          final label = data[index][labelKey]?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.grey700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        return const Text('');
      },
      reservedSize: 60,
    );
  }

  // Bottom titles for charts
  static SideTitles getBottomTitles(
    List<Map<String, dynamic>> data,
    String labelKey,
  ) {
    return SideTitles(
      showTitles: true,
      getTitlesWidget: (value, meta) {
        final index = value.toInt();
        if (index >= 0 && index < data.length) {
          final label = data[index][labelKey]?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.grey700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        return const Text('');
      },
      reservedSize: 40,
    );
  }
}
