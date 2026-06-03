import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewModels/auth_view_model.dart';
import '../viewModels/deck_view_model.dart';
import '../viewModels/meta_view_model.dart';
import 'login_screen.dart';
import 'meta_environment_screen.dart';
import 'qr_scanner_screen.dart';
import 'my_decks_screen.dart';
import 'test_connection_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _handleProfileClick(BuildContext context, UserAuthState authState, AuthViewModel authNotifier) {
    // 🔥 如果不是真實使用者（包含未登入或匿名），則跳轉登入頁
    if (!authState.isRealUser) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      return;
    }

    // 已登入（真實使用者）顯示會員中心
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('會員中心'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('帳號: ${authState.user?.email}'),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('登出帳號'),
              onTap: () async {
                // 1. 執行登出邏輯
                await authNotifier.signOut();
                if (context.mounted) {
                  // 2. 關閉會員中心對話框
                  Navigator.pop(context); 
                  
                  // 3. 立即跳轉至登入介面
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                  
                  // 4. 顯示提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已成功登出'), backgroundColor: Colors.blueGrey),
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final metaState = ref.watch(metaViewModelProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 移除手動背景色，交給 MaterialApp 的 theme 處理
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 每次點擊出品，先清空編輯器緩存，確保是「新牌組」
          ref.read(deckViewModelProvider.notifier).clearEditor();
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

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavIcon(context, Icons.home, '首頁', true, () {}),
              _buildNavIcon(context, Icons.store_outlined, '市場', false, () {}),
              const SizedBox(width: 40),
              _buildNavIcon(context, Icons.chat_bubble_outline, '消息', false, () {}),
              _buildNavIcon(context, authState.isRealUser ? Icons.person : Icons.person_outline, '個人', false, 
                () => _handleProfileClick(context, authState, ref.read(authViewModelProvider.notifier))),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(metaViewModelProvider.notifier).fetchRanking();
            await ref.read(metaViewModelProvider.notifier).fetchMetaEnvironment();
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSearchArea(context),
                _buildBanner(),
                _buildQuickActions(context),
                _buildHomeMetaPreview(context, metaState),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text('トップ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Text('|', style: TextStyle(color: Colors.grey.shade600)),
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

  Widget _buildSearchArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  // 這裡之後會改用 CardLibraryViewModel
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TestConnectionScreen()));
                }
              },
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
          const SizedBox(width: 10),
          // QR 掃描導入按鈕
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.black, size: 18),
                  Text('QR導入', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
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
      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(15)),
      child: const Center(child: Text('熱門活動橫幅', style: TextStyle(fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _quickButton(Icons.analytics_outlined, '對戰環境', Colors.purple.shade50, const Color(0xFF8E24AA), () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MetaEnvironmentScreen()));
          }),
          _quickButton(Icons.dashboard_customize_outlined, '智能組牌', Colors.pink.shade50, Colors.pink, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TestConnectionScreen()));
          }),
          _quickButton(Icons.style_outlined, '我的牌組', Colors.blue.shade50, Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyDecksScreen()));
          }),
          _quickButton(Icons.card_giftcard, '主題活動', Colors.orange.shade50, Colors.orange, () {}),
        ],
      ),
    );
  }

  Widget _quickButton(IconData icon, String label, Color bg, Color iconColor, VoidCallback onTap) {
    return InkWell(
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

  Widget _buildHomeMetaPreview(BuildContext context, MetaState metaState) {
    if (metaState.isLoading) {
      return const Padding(padding: EdgeInsets.all(24.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final previewList = metaState.metaData.take(3).toList();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('對戰環境', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(width: 6),
                  const Icon(Icons.circle, color: Colors.green, size: 8),
                ],
              ),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MetaEnvironmentScreen())),
                child: const Text('查看更多 >', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFF2C2C35)),
              itemBuilder: (context, index) {
                final item = previewList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Text('#${index + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: index == 0 ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.7))),
                      const SizedBox(width: 16),
                      Expanded(child: Text('${item['name_zh'] ?? '未知系列'}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('${item['share_rate']}%', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
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

  Widget _buildNavIcon(BuildContext context, IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.amber.shade800 : Colors.grey, size: 28),
          Text(label, style: TextStyle(fontSize: 10, color: isActive ? Colors.amber.shade800 : Colors.grey)),
        ],
      ),
    );
  }
}
