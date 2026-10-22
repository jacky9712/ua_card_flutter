// lib/widgets/deck_health_summary.dart
// 組牌頁底部結算列的牌組健檢摘要：顏色張數 + 必要能源迷你長條，點擊展開完整分布。
import 'package:flutter/material.dart';
import '../models/ua_card.dart';
import '../utils/deck_stats.dart';
import 'deck_distribution_charts.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_theme.dart';

class DeckHealthSummary extends StatefulWidget {
  /// 依張數展開的卡片清單（DeckState.expandedCards）
  final List<UACard> cards;

  const DeckHealthSummary({super.key, required this.cards});

  @override
  State<DeckHealthSummary> createState() => _DeckHealthSummaryState();
}

class _DeckHealthSummaryState extends State<DeckHealthSummary> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = DeckStats.colorCounts(widget.cards);
    final energy = DeckStats.energyDistribution(widget.cards);
    final maxEnergy = energy.values.fold<int>(0, (a, b) => a > b ? a : b);
    // 展開區的圖表和標題跟牌組詳情頁取一樣的主題色，兩頁才會長得一樣。
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final surfaceColor = Theme.of(context).cardColor;
    final sectionTitleStyle = TextStyle(
      color: textColor,
      fontSize: 16,
      fontWeight: FontWeight.w900,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: const Key('deckHealthSummary'),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  context.l10n.deckHealthTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: colors.isEmpty
                      ? Text(
                          context.l10n.deckHealthEmpty,
                          key: const Key('deckHealthEmpty'),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: colors.entries
                              .map(
                                (e) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 4,
                                      backgroundColor: AppColors.cardColor(e.key),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${e.value}',
                                      key: Key('deckHealthColorCount_${e.key}'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                ),
                SizedBox(
                  height: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: energy.entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1.5),
                            child: SizedBox(
                              key: Key('deckHealthCostBar_${e.key}'),
                              width: 6,
                              height: maxEnergy > 0 ? 2 + 18 * e.value / maxEnergy : 2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.cardPurple,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                // 摘要在畫面底部，展開時整條結算列往上長：收合時箭頭朝上（點了往上打開），展開時朝下。
                Icon(
                  _expanded ? Icons.expand_more : Icons.expand_less,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ConstrainedBox(
            key: const Key('deckHealthDetails'),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.4,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.costDistribution, style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  EnergyDistributionChart(
                    data: energy,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                  Text(context.l10n.triggerDistribution, style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  TriggerDistributionGrid(
                    data: DeckStats.triggerDistribution(widget.cards),
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
