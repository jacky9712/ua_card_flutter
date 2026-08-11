import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewModels/auth_view_model.dart';
import '../viewModels/card_library_view_model.dart';
import '../viewModels/meta_view_model.dart';
import '../viewModels/profile_view_model.dart';
import 'login_screen.dart';
import 'location_hub_screen.dart';
import 'match_records_screen.dart';
import 'meta_environment_screen.dart';
import 'profile_setup_dialog.dart';
import 'my_qr_code_screen.dart';
import 'qr_scanner_screen.dart';
import 'my_decks_screen.dart';
import 'recommended_decks_screen.dart';
import 'test_connection_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // 「消息」目前直接連到 UNION ARENA 官網最新情報頁，不在 App 內另外做一份消息列表。
  Future<void> _openOfficialNews() async {
    final uri = Uri.parse('https://www.unionarena-tcg.com/jp/news/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _handleProfileClick(BuildContext context, WidgetRef ref, UserAuthState authState, AuthViewModel authNotifier) {
    // 🔥 訪客（匿名）帳號以前是直接強制跳登入頁，完全沒有「只是設個暱稱」的路徑——
    // 但「分享位置」「紀錄勝敗」這些功能訪客也該能用（掃 QR 加對手不需要正式帳號），
    // 所以改成先給選擇，不再無條件強制跳轉。
    if (!authState.isRealUser) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('個人設定'),
          content: const Text('你目前是訪客身分。可以先設定暱稱讓其他玩家認得你，或是登入/註冊正式帳號。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyQrCodeScreen()));
              },
              child: const Text('我的 QR 名片'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                showDialog(context: context, builder: (_) => const ProfileSetupDialog());
              },
              child: const Text('設定暱稱'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              child: const Text('登入/註冊'),
            ),
          ],
        ),
      );
      return;
    }

    // 已登入（真實使用者）顯示會員中心
    final displayName = ref.read(profileViewModelProvider).displayName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('會員中心'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('帳號: ${authState.user?.email}'),
            const SizedBox(height: 8),
            Text('暱稱: ${displayName ?? '（尚未設定）'}'),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.badge_outlined, color: Colors.amber),
              title: const Text('編輯暱稱'),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (_) => const ProfileSetupDialog());
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.amber),
              title: const Text('我的 QR 名片'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyQrCodeScreen()));
              },
            ),
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

    return Scaffold(
      // 移除手動背景色，交給 MaterialApp 的 theme 處理
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavIcon(context, Icons.home, '首頁', true, () {}),
              _buildNavIcon(context, Icons.chat_bubble_outline, '消息', false, _openOfficialNews),
              _buildNavIcon(context, authState.isRealUser ? Icons.person : Icons.person_outline, '個人', false,
                () => _handleProfileClick(context, ref, authState, ref.read(authViewModelProvider.notifier))),
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
                _buildSearchArea(context, ref),
                const _HomeBannerAd(),
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text('トップ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSearchArea(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onSubmitted: (text) {
                final query = text.trim();
                if (query.isEmpty) return;
                // 直接跳組牌頁面會把打好的關鍵字丟掉、要使用者重打一次，
                // 這裡先把查詢字串灌進共用的 CardLibraryViewModel，組牌頁面
                // initState 會從同一個 provider 讀回搜尋框內容，兩邊就對得上。
                ref.read(cardLibraryViewModelProvider.notifier).updateSearchQuery(query);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TestConnectionScreen()));
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
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    // 拿掉「主題活動」之後剩 6 個入口，改用 3 欄排成剛好 2 整排，
    // 不會像 4 欄那樣第二排只填一半、看起來像漏東西。
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
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
          _quickButton(Icons.emoji_events_outlined, '上位卡組', Colors.red.shade50, Colors.redAccent, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RecommendedDecksScreen()));
          }),
          _quickButton(Icons.military_tech_outlined, '戰績紀錄', Colors.teal.shade50, Colors.teal, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchRecordsScreen()));
          }),
          _quickButton(Icons.location_on_outlined, '約戰地點', Colors.indigo.shade50, Colors.indigo, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationHubScreen()));
          }),
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

/// 首頁的橫幅廣告（Google AdMob）。
///
/// 目前用的是 Google 公開的測試廣告單元 ID，任何裝置/帳號都看得到測試素材，
/// 不會產生真的收益。正式上架前要到 AdMob 後台申請自己的 App，把這裡的
/// [_testBannerAdUnitId] 換成正式的廣告單元 ID，同時把
/// android/app/src/main/AndroidManifest.xml 的 APPLICATION_ID 跟
/// ios/Runner/Info.plist 的 GADApplicationIdentifier 換成正式的 App ID。
///
/// AdMob 只支援 Android/iOS，桌面/Web 平台沒有對應實作，這兩個平台維持原本
/// 的靜態佔位版面。
class _HomeBannerAd extends StatefulWidget {
  const _HomeBannerAd();

  @override
  State<_HomeBannerAd> createState() => _HomeBannerAdState();
}

class _HomeBannerAdState extends State<_HomeBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  bool get _supportsAds =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  String get _testBannerAdUnitId => defaultTargetPlatform == TargetPlatform.iOS
      ? 'ca-app-pub-3940256099942544/2934735716' // Google 官方 iOS 測試橫幅 ID
      : 'ca-app-pub-3940256099942544/6300978111'; // Google 官方 Android 測試橫幅 ID

  @override
  void initState() {
    super.initState();
    if (_supportsAds) {
      _loadAd();
    }
  }

  void _loadAd() {
    BannerAd(
      adUnitId: _testBannerAdUnitId,
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // 載入失敗（例如沒有網路、測試裝置沒被 AdMob 認可）就維持佔位版面，
          // 不讓整個首頁因為廣告載入失敗而壞掉。
          ad.dispose();
        },
      ),
    ).load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Widget _buildPlaceholder() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(15)),
      child: const Center(child: Text('熱門活動橫幅', style: TextStyle(fontWeight: FontWeight.bold))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (_isLoaded && ad != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        alignment: Alignment.center,
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      );
    }
    return _buildPlaceholder();
  }
}
