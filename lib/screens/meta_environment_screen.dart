import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/card_view_model.dart';

class MetaEnvironmentScreen extends ConsumerStatefulWidget {
  const MetaEnvironmentScreen({super.key});

  @override
  ConsumerState<MetaEnvironmentScreen> createState() => _MetaEnvironmentScreenState();
}

class _MetaEnvironmentScreenState extends ConsumerState<MetaEnvironmentScreen> {
  @override
  void initState() {
    super.initState();
    // 進入畫面時自動撈取環境數據
    Future.microtask(() => ref.read(cardViewModelProvider.notifier).fetchMetaEnvironment());
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(cardViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('對戰環境分析', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: uiState.metaData.isEmpty
          ? const Center(
        child: Text('目前還沒有足夠的賽場數據來進行分析', style: TextStyle(color: Colors.grey)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: uiState.metaData.length,
        itemBuilder: (context, index) {
          final item = uiState.metaData[index];
          final seriesName = item['name_zh'] ?? '未知系列';
          final shareRate = (item['share_rate'] as num?)?.toDouble() ?? 0.0;
          final useCount = item['use_count'] ?? 0;

          // 設定前三名的專屬顏色
          Color rankColor;
          if (index == 0) rankColor = Colors.amber; // 金
          else if (index == 1) rankColor = Colors.grey.shade400; // 銀
          else if (index == 2) rankColor = const Color(0xFFCD7F32); // 銅
          else rankColor = Colors.blueGrey.shade100;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: index < 3 ? 4 : 1, // 前三名陰影較深
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 排名數字
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: rankColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: index < 3 ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 數據進度條區塊
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                seriesName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$shareRate%',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 條狀圖
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: shareRate / 100, // 轉換為 0.0 ~ 1.0
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              index < 3 ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '收錄牌組中包含 $useCount 張',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}