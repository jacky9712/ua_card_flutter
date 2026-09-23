import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../viewModels/meta_view_model.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_theme.dart';

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
    
    final metaData = metaState.metaData;

    return Scaffold(
      // 移除手動背景色，交給 MaterialApp 處理
      appBar: AppBar(
        title: Text(context.l10n.metaLeaderboardTitle, style: TextStyle(fontWeight: FontWeight.bold)),
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
                    child: _buildSummaryHeader(metaData, metaState.fetchedAt),
                  ),
                  if (metaData.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        // 抓取失敗跟真的沒資料要分開講，失敗時給重試
                        child: metaState.loadFailed
                            ? Column(
                                children: [
                                  Text(context.l10n.loadFailed, style: TextStyle(color: Colors.grey)),
                                  TextButton.icon(
                                    onPressed: () => ref.read(metaViewModelProvider.notifier).fetchMetaEnvironment(),
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: Text(context.l10n.retry),
                                  ),
                                ],
                              )
                            : Center(child: Text(context.l10n.noMetaData, style: TextStyle(color: Colors.grey))),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = metaData[index];
                            return _buildLeaderboardTile(index + 1, item);
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

  Widget _buildSummaryHeader(List<Map<String, dynamic>> data, DateTime? fetchedAt) {
    final int totalDecks = data.fold(0, (sum, item) => sum + ((item['use_count'] as int?) ?? 0));
    final int activeSeries = data.length;
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
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
              Text(context.l10n.metaTrend, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              if (fetchedAt != null)
                Text(context.l10n.updatedAt(DateFormat('MM/dd HH:mm').format(fetchedAt)),
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context.l10n.totalDecks, '$totalDecks', Icons.layers),
              _buildStatItem(context.l10n.activeSeries, '$activeSeries', Icons.category),
              _buildStatItem(context.l10n.topShare, '${data.isNotEmpty ? data[0]['share_rate'] : 0}%', Icons.pie_chart),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLeaderboardTile(int rank, Map<String, dynamic> item) {
    Color rankColor = Colors.grey;
    if (rank == 1) rankColor = AppColors.gold;
    if (rank == 2) rankColor = const Color(0xFFC0C0C0);
    if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
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
                    item['name_zh'] ?? context.l10n.unknownSeries,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.useCount('${item['use_count'] ?? 0}'),
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
