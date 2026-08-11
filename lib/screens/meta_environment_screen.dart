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
    
    final metaData = metaState.metaData;

    return Scaffold(
      // 移除手動背景色，交給 MaterialApp 處理
      appBar: AppBar(
        title: const Text('對戰環境排行榜', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, // 讓它透明以顯示 Scaffold 的底色
        elevation: 0,
        centerTitle: true,
      ),
      body: metaState.isLoading && metaData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(metaViewModelProvider.notifier).fetchMetaEnvironment(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildSummaryHeader(metaData, isDarkMode),
                  ),
                  if (metaData.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text('目前尚無環境資料', style: TextStyle(color: Colors.grey))),
                      ),
                    )
                  else
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
    final int totalDecks = data.fold(0, (sum, item) => sum + ((item['use_count'] as int?) ?? 0));
    final int activeSeries = data.length;
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
              _buildStatItem('總計牌組', '$totalDecks', Icons.layers, isDarkMode),
              _buildStatItem('活躍系列', '$activeSeries', Icons.category, isDarkMode),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name_zh'] ?? '未知系列',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDarkMode ? Colors.white : Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '使用次數: ${item['use_count'] ?? 0} 次',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${item['share_rate'] ?? 0}%',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }
}
