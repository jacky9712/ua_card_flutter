// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/card_view_model.dart';
import 'meta_environment_screen.dart';
import 'my_decks_screen.dart';
import 'test_connection_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(cardViewModelProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF141419) : Colors.white,
      // 🏆 中央凸起按鈕 (出品 / 產生牌組)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 點擊後跳轉到你原本寫好的組牌畫面
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => const TestConnectionScreen()));
        },
        backgroundColor: Colors.amber,
        shape: const CircleBorder(),
        elevation: 5,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.black, size: 20),
            Text('出品', style: TextStyle(color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🏆 底部導航欄
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavIcon(Icons.home, '首頁', true),
              _buildNavIcon(Icons.store_outlined, '市場', false),
              const SizedBox(width: 40), // 給中央按鈕留位置
              _buildNavIcon(Icons.chat_bubble_outline, '消息', false),
              _buildNavIcon(Icons.person_outline, '個人', false),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1️⃣ 頂部狀態列 (語言切換)
              _buildHeader(),

              // 2️⃣ 搜尋區 (整合你原本的 updateSearchQuery)
              _buildSearchArea(ref, context),

              // 3️⃣ 橫幅廣告
              _buildBanner(),

              // 4️⃣ 四大快速功能按鈕
              _buildQuickActions(context, uiState),

              // 5️⃣ 對戰環境預覽 (整合自原本的 RankingSection)
              _buildHomeMetaPreview(context, uiState),

              const SizedBox(height: 100), // 給底部按鈕留白
            ],
          ),
        ),
      ),
    );
  }

  // --- 各區塊組件實作 ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text('トップ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Text('|', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(width: 10),
          const Text(
              '投稿清單', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.language, size: 16),
                Text(' 日本語', style: TextStyle(fontSize: 12)),
                Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchArea(WidgetRef ref, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (text) {
                ref.read(cardViewModelProvider.notifier).updateSearchQuery(text);
              },
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const TestConnectionScreen()));
                }
              },
              decoration: InputDecoration(
                hintText: '搜尋卡號或卡名...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // AI 掃描按鈕 (漸層配色)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Colors.black, Color(0xFF421E91)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.camera_alt, color: Colors.white, size: 18),
                Text('AI檢索', style: TextStyle(color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(15),
        // 這裡可以換成 Image.network 載入真實廣告圖
      ),
      child: const Center(child: Text(
          '熱門活動橫幅', style: TextStyle(fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildQuickActions(BuildContext context, dynamic uiState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. 對戰環境 (對應 Kadoraba 的 デッキ広場)
          _quickButton(
              Icons.analytics_outlined,
              '對戰環境',
              Colors.purple.shade50,
              const Color(0xFF8E24AA),
                  () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const MetaEnvironmentScreen()));
              }
          ),

          // 2. 智能組牌 (前往你的黑金組牌主戰場)
          _quickButton(
              Icons.dashboard_customize_outlined,
              '智能組牌',
              Colors.pink.shade50,
              Colors.pink,
                  () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const TestConnectionScreen()));
              }
          ),

          // 3. 我的牌組 (對應 Kadoraba 的 マイカード)
          _quickButton(
              Icons.style_outlined,
              '我的牌組',
              Colors.blue.shade50,
              Colors.blue,
                  () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const MyDecksScreen()));
              }
          ),

          // 4. 抽獎/其他活動 (預留功能)
          _quickButton(
              Icons.card_giftcard,
              '主題活動',
              Colors.orange.shade50,
              Colors.orange,
                  () {
                // 暫時留空或跳轉至活動
              }
          ),
        ],
      ),
    );
  }

  Widget _quickButton(IconData icon, String label, Color bg, Color iconColor,
      VoidCallback onTap) {
    return InkWell( // 讓按鈕可以點擊
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            width: 55, height: 55,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRankingSection(CardState uiState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('對戰環境排行',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text('查看更多 >',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 15),

          if (uiState.rankingList.isEmpty)
            const Center(
                child: Text('暫無數據', style: TextStyle(color: Colors.grey)))
          else
            ...uiState.rankingList
                .asMap()
                .entries
                .map((entry) {
              int index = entry.key;
              var item = entry.value;
              return _rankingRow(
                  '#${index + 1}',
                  item['name_zh'] ?? '未知系列',
                  '${item['share_rate']}%',
                  '${item['use_count']}'
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _rankingRow(String rank, String title, String share, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(rank, style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(width: 15),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          Text(share, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 20),
          Text(count, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? Colors.amber.shade800 : Colors.grey,
            size: 28),
        Text(label, style: TextStyle(fontSize: 10,
            color: isActive ? Colors.amber.shade800 : Colors.grey)),
      ],
    );
  }

  Widget _buildHomeMetaPreview(BuildContext context, dynamic uiState) {
    // 防呆：如果 ViewModel 還沒撈到環境數據，就顯示輕量 Loading
    if (uiState.metaData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // 只取前三名塞在首頁當預覽簡報
    final previewList = uiState.metaData.take(3).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('對戰環境', style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(width: 6),
                  const Icon(Icons.circle, color: Colors.green, size: 8),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const MetaEnvironmentScreen()));
                },
                child: const Text('查看更多 >',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 簡報白底卡片矩陣
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2C2C35)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: previewList.length,
              separatorBuilder: (context, index) =>
              const Divider(height: 1, color: Color(0xFF2C2C35)),
              itemBuilder: (context, index) {
                final item = previewList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Text('#${index + 1}', style: TextStyle(
                          fontWeight: FontWeight.w900, color: index == 0
                          ? const Color(0xFFFFD700)
                          : Colors.white70)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '${item['name_zh'] ?? '未知系列'}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${item['share_rate']}%',
                          style: const TextStyle(color: Color(0xFFFFD700),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}