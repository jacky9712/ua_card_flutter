import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:translator/translator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // 🔥 必加：用於日期格式化
import 'package:supabase_flutter/supabase_flutter.dart'; // 🔥 必加：抓取歷史數據
import '../models/ua_card.dart';

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
      print('抓取歷史價格失敗: $e');
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _translateTexts() async {
    if (_translatedEffect != null || _translatedTrigger != null) {
      setState(() => _showTranslation = !_showTranslation);
      return;
    }
    setState(() => _isTranslating = true);
    try {
      if (widget.card.effectText != null && widget.card.effectText!.isNotEmpty) {
        final effectResult = await _translator.translate(widget.card.effectText!, to: 'zh-tw');
        _translatedEffect = effectResult.text;
      }
      if (widget.card.triggerText != null && widget.card.triggerText!.isNotEmpty) {
        final triggerResult = await _translator.translate(widget.card.triggerText!, to: 'zh-tw');
        _translatedTrigger = triggerResult.text;
      }
      setState(() => _showTranslation = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('翻譯失敗')));
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
        color: Colors.white,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85), // 稍微拉高一點放圖表
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: TextButton.icon(
                    onPressed: _isTranslating ? null : _translateTexts,
                    icon: _isTranslating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(_showTranslation ? Icons.g_translate : Icons.translate),
                    label: Text(_showTranslation ? '顯示原文' : '中文翻譯'),
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
                    Text(widget.card.name ?? '未知名稱', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(widget.card.cardNumber, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBadge('BP', widget.card.bp?.toString() ?? '-'),
                        _buildStatBadge('AP 消耗', widget.card.apCost?.toString() ?? '-'),
                        _buildStatBadge('顏色', widget.card.color ?? '-'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ⚔️ 效果區
                    if (widget.card.effectText != null) ...[
                      const Text('效果', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 4),
                      Text(_showTranslation ? (_translatedEffect ?? '') : widget.card.effectText!, style: const TextStyle(height: 1.4)),
                      const SizedBox(height: 16),
                    ],

                    // ⚡ 觸發區
                    if (widget.card.triggerText != null) ...[
                      const Text('觸發 (Trigger)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 4),
                      Text(_showTranslation ? (_translatedTrigger ?? '') : widget.card.triggerText!, style: const TextStyle(height: 1.4)),
                      const SizedBox(height: 16),
                    ],

                    // 📈 價格趨勢區 (放在這裡！)
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text('價格趨勢 (JPY)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  // --- 你提供的 _buildPriceChart 內容 ---
  Widget _buildPriceChart(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('暫無歷史價格數據', style: TextStyle(color: Colors.grey))),
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
          minY: (minPrice - rangePadding).clamp(0, double.infinity),
          maxY: maxPrice + rangePadding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.amber,
              barWidth: 3,
              belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.amber.withOpacity(0.3), Colors.amber.withOpacity(0)]
                  )
              ),
              dotData: const FlDotData(show: false),
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