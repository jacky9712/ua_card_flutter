// lib/widgets/deck_distribution_charts.dart
// 牌組詳情頁與組牌頁共用的能源分布 / 觸發分布圖表。
import 'package:flutter/material.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_theme.dart';

class EnergyDistributionChart extends StatelessWidget {
  final Map<int, int> data;
  final Color surfaceColor;
  final Color textColor;

  const EnergyDistributionChart({
    super.key,
    required this.data,
    required this.surfaceColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = data.values.fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: data.entries.map((entry) {
          final barWidthRatio = maxVal > 0 ? (entry.value / maxVal) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                SizedBox(
                  width: 35,
                  child: Text(
                    context.l10n.energyCost(entry.key == 6 ? '6+' : '${entry.key}'),
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: barWidthRatio == 0 ? 0.02 : barWidthRatio,
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.cardPurple, AppColors.cardPurpleLight],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 25,
                  child: Text(
                    '${entry.value}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TriggerDistributionGrid extends StatelessWidget {
  final Map<String, int> data;
  final Color surfaceColor;
  final Color textColor;

  const TriggerDistributionGrid({
    super.key,
    required this.data,
    required this.surfaceColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final triggerColors = {
      'SPECIAL': Colors.redAccent,
      'COLOR': Colors.orangeAccent,
      'FINAL': Colors.blueAccent,
      'DRAW': Colors.greenAccent,
      'GET': Colors.yellowAccent,
      'ACTIVE': Colors.cyanAccent,
      'RAID': Colors.pinkAccent,
      'OTHER': Colors.blueGrey,
      'NONE': Colors.grey,
    };

    final sortedKeys = [
      'ACTIVE',
      'GET',
      'DRAW',
      'RAID',
      'COLOR',
      'SPECIAL',
      'FINAL',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final key = sortedKeys[index];
          final count = data[key] ?? 0;
          final color = triggerColors[key] ?? Colors.grey;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  key,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.cardCount(count),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
