// lib/widgets/deck_health_summary.dart
// 組牌頁底部結算列的牌組健檢摘要：顏色張數 + 必要能源迷你長條，點擊展開完整分布、規則提醒與 0 能起手機率。
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
    final dupWarnings = DeckStats.overLimitCardNumbers(widget.cards);
    final triggerWarnings = DeckStats.overLimitTriggers(widget.cards);
    final warningCount = dupWarnings.length + triggerWarnings.length;
    final zeroEnergy = DeckStats.zeroEnergyCount(widget.cards);
    final zeroOdds = DeckStats.openingHandHitProbability(
      deckSize: widget.cards.length,
      hits: zeroEnergy,
    );
    final zeroOddsWithMulligan = DeckStats.openingHandHitProbability(
      deckSize: widget.cards.length,
      hits: zeroEnergy,
      redraws: 1,
    );
    // 觸發沒放滿只是提醒，不算進摘要列的警示數量。
    final underFilledTexts = [
      for (final e in DeckStats.underFilledTriggers(widget.cards).entries)
        context.l10n.deckHealthTriggerUnderfilled(_triggerLabel(context, e.key), e.value),
    ];
    final warningTexts = [
      for (final e in dupWarnings.entries)
        context.l10n.deckHealthDuplicateCardWarning(e.key, e.value),
      for (final e in triggerWarnings.entries)
        context.l10n.deckHealthTriggerWarning(_triggerLabel(context, e.key), e.value),
    ];
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
                if (warningCount > 0) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.warning_amber_rounded,
                    key: Key('deckHealthWarningIcon'),
                    size: 16,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$warningCount',
                    key: const Key('deckHealthWarningCount'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
                  if (warningTexts.isNotEmpty) ...[
                    Text(context.l10n.deckHealthRuleWarnings, style: sectionTitleStyle),
                    const SizedBox(height: 8),
                    for (var i = 0; i < warningTexts.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: AppColors.amber,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                warningTexts[i],
                                key: Key('deckHealthWarning_$i'),
                                style: TextStyle(color: textColor, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  if (underFilledTexts.isNotEmpty) ...[
                    Text(context.l10n.deckHealthTriggerReminders, style: sectionTitleStyle),
                    const SizedBox(height: 8),
                    for (var i = 0; i < underFilledTexts.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                underFilledTexts[i],
                                key: Key('deckHealthTriggerReminder_$i'),
                                style: TextStyle(color: textColor, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  if (zeroOdds != null) ...[
                    Text(context.l10n.deckHealthOpeningHand, style: sectionTitleStyle),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.deckHealthZeroEnergyOdds(
                        zeroEnergy,
                        (zeroOdds * 100).toStringAsFixed(1),
                        (zeroOddsWithMulligan! * 100).toStringAsFixed(1),
                      ),
                      key: const Key('deckHealthZeroEnergyOdds'),
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                  ],
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

  // overLimitTriggers 回傳的是統計用的 key（SPECIAL / FINAL），提醒文字換成各語系的名稱。
  String _triggerLabel(BuildContext context, String key) => switch (key) {
        'SPECIAL' => context.l10n.triggerNameSpecial,
        'FINAL' => context.l10n.triggerNameFinal,
        'COLOR' => context.l10n.triggerNameColor,
        _ => key,
      };
}
