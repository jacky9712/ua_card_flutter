import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewModels/meta_view_model.dart';

class MetaEnvironmentScreen extends ConsumerStatefulWidget {
  const MetaEnvironmentScreen({super.key});

  @override
  ConsumerState<MetaEnvironmentScreen> createState() => _MetaEnvironmentScreenState();
}

class _MetaEnvironmentScreenState extends ConsumerState<MetaEnvironmentScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(metaViewModelProvider.notifier).fetchMetaEnvironment());
  }

  @override
  Widget build(BuildContext context) {
    final metaState = ref.watch(metaViewModelProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final metaData = metaState.metaData.isEmpty ? [
      {'name_zh': '咒術迴戰 第1彈', 'share_rate': 35.5, 'use_count': 142, 'color': '紫', 'trend': 'up'},
      {'name_zh': 'HUNTER×HUNTER 獵人', 'share_rate': 28.0, 'use_count': 112, 'color': '黃', 'trend': 'down'},
      {'name_zh': 'Code Geass 反叛的魯路修', 'share_rate': 15.2, 'use_count': 61, 'color': '青', 'trend': 'stable'},
      {'name_zh': '偶像大師 閃耀色彩', 'share_rate': 10.8, 'use_count': 43, 'color': '黃', 'trend': 'new'},
      {'name_zh': '鬼滅之刃', 'share_rate': 10.5, 'use_count': 42, 'color': '紅', 'trend': 'stable'},
    ] : metaState.metaData;

    return Scaffold(
      // 移除手動背景色，交給 MaterialApp 處理
      appBar: AppBar(
        title: const Text('對戰環境排行榜', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, // 讓它透明以顯示 Scaffold 的底色
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(metaViewModelProvider.notifier).fetchMetaEnvironment(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildSummaryHeader(metaData, isDarkMode),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = metaData[index];
                    return _buildLeaderboardTile(index + 1, item, isDarkMode);
                  },
                  childCount: metaData.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(List<Map<String, dynamic>> data, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('環境趨勢分析', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
              const Spacer(),
              Text('更新於: ${DateTime.now().toString().substring(5, 16)}', 
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('總計牌組', '420', Icons.layers, isDarkMode),
              _buildStatItem('活躍系列', '12', Icons.category, isDarkMode),
              _buildStatItem('主流占比', '${data.isNotEmpty ? data[0]['share_rate'] : 0}%', Icons.pie_chart, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isDarkMode) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLeaderboardTile(int rank, Map<String, dynamic> item, bool isDarkMode) {
    Color rankColor = Colors.grey;
    if (rank == 1) rankColor = const Color(0xFFFFD700);
    if (rank == 2) rankColor = const Color(0xFFC0C0C0);
    if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3 ? rankColor.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank <= 3 ? rankColor : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            _buildColorTag(item['color'] ?? '無'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name_zh'] ?? (item['name'] ?? '未知系列'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDarkMode ? Colors.white : Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '使用次數: ${item['use_count'] ?? item['count'] ?? 0} 次',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item['share_rate'] ?? item['rate'] ?? 0}%',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.blueAccent),
                ),
                _buildTrendIcon(item['trend']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTag(String colorName) {
    Color c = Colors.grey;
    switch (colorName) {
      case '紅': c = Colors.red; break;
      case '青': c = Colors.blue; break;
      case '綠': c = Colors.green; break;
      case '黃': c = Colors.yellow.shade700; break;
      case '紫': c = Colors.purple; break;
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }

  Widget _buildTrendIcon(String? trend) {
    switch (trend) {
      case 'up':
        return const Icon(Icons.trending_up, color: Colors.red, size: 16);
      case 'down':
        return const Icon(Icons.trending_down, color: Colors.blue, size: 16);
      case 'new':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
          child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
        );
      default:
        return const Icon(Icons.trending_flat, color: Colors.grey, size: 16);
    }
  }
}
