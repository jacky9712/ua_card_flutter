import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:translator/translator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // 🔥 必加：用於日期格式化
import 'package:supabase_flutter/supabase_flutter.dart'; // 🔥 必加：抓取歷史數據
import '../models/ua_card.dart';
import '../l10n/l10n_ext.dart';

class CardDetailDialog extends StatefulWidget {
  final UACard card;

  const CardDetailDialog({super.key, required this.card});

  @override
  State<CardDetailDialog> createState() => _CardDetailDialogState();
}

class _CardDetailDialogState extends State<CardDetailDialog> {
  final _translator = GoogleTranslator();
  final _supabase = Supabase.instance.client;

  bool _isTranslating = false;
  bool _showTranslation = false;
  String? _translatedEffect;
  String? _translatedTrigger;

  // 🔥 歷史價格相關狀態
  List<Map<String, dynamic>> _priceHistory = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _fetchPriceHistory(); // 🔥 Dialog 一打開就開始抓價格歷史
  }

  // 🔥 抓取歷史價格邏輯
  Future<void> _fetchPriceHistory() async {
    try {
      final response = await _supabase
          .from('price_history')
          .select('price_jpy, created_at')
          .eq('card_id', widget.card.id as Object) // 這裡確保 id 型別對齊 SQL
          .order('created_at', ascending: true)
          .limit(20);

      setState(() {
        _priceHistory = List<Map<String, dynamic>>.from(response);
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint('抓取歷史價格失敗: $e');
      setState(() => _isLoadingHistory = false);
    }
  }

  // 卡片原文是日文：介面是日文就不需要翻譯，其他語言翻成介面語言
  String? _translateTarget(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ja':
        return null;
      case 'en':
        return 'en';
      default:
        return 'zh-tw';
    }
  }

  Future<void> _translateTexts() async {
    final target = _translateTarget(context);
    if (target == null) return;
    final l10n = context.l10n;
    if (_translatedEffect != null || _translatedTrigger != null) {
      setState(() => _showTranslation = !_showTranslation);
      return;
    }
    setState(() => _isTranslating = true);
    try {
      if (widget.card.effectText != null && widget.card.effectText!.isNotEmpty) {
        final effectResult = await _translator.translate(widget.card.effectText!, to: target);
        _translatedEffect = effectResult.text;
      }
      if (widget.card.triggerText != null && widget.card.triggerText!.isNotEmpty) {
        final triggerResult = await _translator.translate(widget.card.triggerText!, to: target);
        _translatedTrigger = triggerResult.text;
      }
      setState(() => _showTranslation = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.translationFailed)));
      }
    } finally {
      setState(() => _isTranslating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85), // 稍微拉高一點放圖表
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_translateTarget(context) == null)
                  const SizedBox.shrink()
                else
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: TextButton.icon(
                    onPressed: _isTranslating ? null : _translateTexts,
                    icon: _isTranslating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(_showTranslation ? Icons.g_translate : Icons.translate),
                    label: Text(_showTranslation ? context.l10n.showOriginal : context.l10n.translateCardText),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.card.imageUrl != null)
                      Center(
                        child: SizedBox(
                          height: 280,
                          child: CachedNetworkImage(
                            imageUrl: widget.card.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(widget.card.name ?? context.l10n.unknownName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(widget.card.cardNumber, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBadge('BP', widget.card.bp?.toString() ?? '-'),
                        _buildStatBadge(context.l10n.apCost, widget.card.apCost?.toString() ?? '-'),
                        _buildStatBadge(context.l10n.colorLabel, widget.card.color ?? '-'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ⚔️ 效果區
                    if (widget.card.effectText != null) ...[
                      Text(context.l10n.effect, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 4),
                      Text(_showTranslation ? (_translatedEffect ?? '') : widget.card.effectText!, style: const TextStyle(height: 1.4)),
                      const SizedBox(height: 16),
                    ],

                    // ⚡ 觸發區
                    if (widget.card.triggerText != null) ...[
                      Text(context.l10n.trigger, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 4),
                      Text(_showTranslation ? (_translatedTrigger ?? '') : widget.card.triggerText!, style: const TextStyle(height: 1.4)),
                      const SizedBox(height: 16),
                    ],

                    // 📈 價格趨勢區 (放在這裡！)
                    const Divider(),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text(context.l10n.priceTrend, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),

                    _isLoadingHistory
                        ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                        : _buildPriceChart(_priceHistory),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 實作像右圖那樣的詳細價格歷史圖表 ---
  Widget _buildPriceChart(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(child: Text(context.l10n.noPriceHistory, style: TextStyle(color: Colors.grey))),
      );
    }

    List<FlSpot> spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['price_jpy'] as num).toDouble());
    }).toList();

    double minPrice = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxPrice = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    double rangePadding = (maxPrice - minPrice) < 10 ? 10 : (maxPrice - minPrice) * 0.2;

    return Container(
      height: 200,
      padding: const EdgeInsets.only(right: 16, top: 10),
      child: LineChart(
        LineChartData(
          // --- 互動設定：滑過顯示價格 ---
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.amber.shade800,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final dateStr = history[spot.x.toInt()]['created_at'];
                  final date = DateTime.parse(dateStr);
                  return LineTooltipItem(
                    '${DateFormat('MM/dd').format(date)}\n¥${spot.y.toInt()}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // --- X 軸日期標籤：格式化日期 ---
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 5 != 0) return const SizedBox(); // 每 5 個點顯示一個標籤
                  int index = value.toInt();
                  if (index >= history.length || index < 0) return const SizedBox();
                  final date = DateTime.parse(history[index]['created_at']);
                  return Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          // --- 數值範圍設定：動態調整 Y 軸，讓線條不要貼地 ---
          minY: (minPrice - rangePadding).clamp(0, double.infinity),
          maxY: maxPrice + rangePadding,
          // --- 線條設計：琥珀色、曲線、漸層填充 ---
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true, // 曲線平滑化
              color: Colors.amber,
              barWidth: 3,
              belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.amber.withValues(alpha: 0.3), Colors.amber.withValues(alpha: 0)]
                  )
              ),
              dotData: const FlDotData(show: false), // 隱藏數據點，滑過才顯示
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}