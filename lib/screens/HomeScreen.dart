// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/card_view_model.dart';
import 'test_connection_screen.dart'; // 導向原本的組牌模式

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(cardViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      // 🏆 中央凸起按鈕 (出品 / 產生牌組)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 點擊後跳轉到你原本寫好的組牌畫面
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TestConnectionScreen()));
        },
        backgroundColor: Colors.amber,
        shape: const CircleBorder(),
        elevation: 5,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.black, size: 20),
            Text('出品', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
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
              _buildSearchArea(ref),

              // 3️⃣ 橫幅廣告
              _buildBanner(),

              // 4️⃣ 四大快速功能按鈕
              _buildQuickActions(context, uiState),

              // 5️⃣ 對戰環境排行榜 (數據展示)
              _buildRankingSection(),

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
          const Text('トップ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Text('|', style: TextStyle(color: Colors.grey.shade300)),
          const SizedBox(width: 10),
          const Text('投稿清單', style: TextStyle(color: Colors.grey, fontSize: 14)),
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

  Widget _buildSearchArea(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (text) => ref.read(cardViewModelProvider.notifier).updateSearchQuery(text),
              decoration: InputDecoration(
                hintText: '搜尋卡號或卡名...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // AI 掃描按鈕 (漸層配色)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.black, Color(0xFF421E91)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.camera_alt, color: Colors.white, size: 18),
                Text('AI檢索', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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
      child: const Center(child: Text('熱門活動橫幅', style: TextStyle(fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildQuickActions(BuildContext context, dynamic uiState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _quickButton(Icons.style, '牌組廣場', Colors.pink.shade50, Colors.pink, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TestConnectionScreen()));
          }),
          _quickButton(Icons.grid_on, '我的卡片', Colors.blue.shade50, Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TestConnectionScreen()));
          }),
          _quickButton(Icons.card_giftcard, '抽獎活動', Colors.orange.shade50, Colors.orange, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TestConnectionScreen()));
          }),
          _quickButton(Icons.edit_note, '首頁編輯', Colors.indigo.shade50, Colors.indigo, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TestConnectionScreen()));
          }),
        ],
      ),
    );
  }

  Widget _quickButton(IconData icon, String label, Color bg, Color iconColor, VoidCallback onTap) {
    return InkWell( // 讓按鈕可以點擊
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            width: 55, height: 55,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRankingSection() {
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
              const Text('對戰環境排行', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text('查看更多 >', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 15),
          _rankingRow('#1', '[紫] 阿米婭 & 陳', '3%', '201'),
          _rankingRow('#2', '[青] 凱爾希', '2.8%', '191'),
          _rankingRow('#3', '[黑] 塔露拉', '2.5%', '185'),
        ],
      ),
    );
  }

  Widget _rankingRow(String rank, String title, String share, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(rank, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
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
        Icon(icon, color: isActive ? Colors.amber.shade800 : Colors.grey, size: 28),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? Colors.amber.shade800 : Colors.grey)),
      ],
    );
  }
}