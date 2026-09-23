import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewModels/auth_view_model.dart';
import '../viewModels/card_library_view_model.dart';
import '../viewModels/deck_view_model.dart';
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
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../viewModels/locale_view_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _handleProfileClick(BuildContext context, WidgetRef ref, UserAuthState authState, AuthViewModel authNotifier) {
    final l10n = AppLocalizations.of(context);
    // 🔥 訪客（匿名）帳號以前是直接強制跳登入頁，完全沒有「只是設個暱稱」的路徑——
    // 但「分享位置」「紀錄勝敗」這些功能訪客也該能用（掃 QR 加對手不需要正式帳號），
    // 所以改成先給選擇，不再無條件強制跳轉。
    if (!authState.isRealUser) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.guestDialogTitle),
          content: Text(l10n.guestDialogBody),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyQrCodeScreen()));
              },
              child: Text(l10n.myQrCard),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                showDialog(context: context, builder: (_) => const ProfileSetupDialog());
              },
              child: Text(l10n.setNickname),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              child: Text(l10n.loginOrRegister),
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
        title: Text(l10n.memberCenter),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.accountLabel(authState.user?.email ?? '')),
            const SizedBox(height: 8),
            Text(l10n.nicknameLabel(displayName ?? l10n.nicknameNotSet)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.badge_outlined, color: AppColors.gold),
              title: Text(l10n.editNickname),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (_) => const ProfileSetupDialog());
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: AppColors.gold),
              title: Text(l10n.myQrCard),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyQrCodeScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(l10n.signOut),
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
                    SnackBar(content: Text(l10n.signedOut)),
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      // 移除手動背景色，交給 MaterialApp 的 theme 處理
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 每次點擊出品，先清空編輯器緩存，確保是「新牌組」
          ref.read(deckViewModelProvider.notifier).clearEditor();
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TestConnectionScreen()));
        },
        shape: const CircleBorder(),
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.black, size: 20),
            Text(l10n.fabCreate, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          // 中間留給 centerDocked 的「出品」按鈕，左右兩半各自平均分配，
          // 缺口才會剛好對在 FAB 正下方，不會壓到旁邊的圖示。
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavIcon(context, Icons.home, l10n.navHome, true, () {}),
                    _buildNavIcon(context, Icons.style_outlined, l10n.navDecks, false,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyDecksScreen()))),
                  ],
                ),
              ),
              const SizedBox(width: 72),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavIcon(context, Icons.chat_bubble_outline, l10n.navMessages, false, () {}),
                    _buildNavIcon(context, authState.isRealUser ? Icons.person : Icons.person_outline, l10n.navProfile, false,
                      () => _handleProfileClick(context, ref, authState, ref.read(authViewModelProvider.notifier))),
                  ],
                ),
              ),
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
            // 內容不滿一頁時預設不能捲，下拉更新就拉不動
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, ref),
                _buildSearchArea(context, ref),
                _buildBanner(context),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.diamond, color: AppColors.gold, size: 20),
          const SizedBox(width: 8),
          const Text('UA DECK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.gold)),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: '',
            position: PopupMenuPosition.under,
            color: AppColors.surface,
            onSelected: (code) => ref.read(localeViewModelProvider.notifier).setLocale(Locale(code)),
            // 選項名稱固定用各語言自己的寫法，切錯語言時才找得回來
            itemBuilder: (context) {
              final current = Localizations.localeOf(context).languageCode;
              return [
                for (final (code, name) in const [('zh', '繁體中文'), ('ja', '日本語'), ('en', 'English')])
                  CheckedPopupMenuItem<String>(value: code, checked: code == current, child: Text(name)),
              ];
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 16, color: AppColors.gold),
                  Text(' ${l10n.languageName}', style: const TextStyle(fontSize: 12)),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
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
              // 底色交給 app_theme 的 inputDecorationTheme，這裡只改成膠囊形 + 聚焦金框
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchHint,
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.surfaceHigh),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // QR 掃描導入按鈕
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.gold, AppColors.amber]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.black, size: 18),
                  Text(AppLocalizations.of(context).qrImport, style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    // 金色漸層外框 + 深色內層，做出卡框的感覺
    return Container(
      margin: const EdgeInsets.all(16),
      height: 110,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, Color(0xFF8A6D00), AppColors.amber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.15), blurRadius: 16)],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF26222E), AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(13.5),
        ),
        child: Center(
          child: Text(AppLocalizations.of(context).bannerPlaceholder, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.gold, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          _quickButton(Icons.analytics_outlined, l10n.actionMeta, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MetaEnvironmentScreen()));
          }),
          _quickButton(Icons.dashboard_customize_outlined, l10n.actionDeckBuilder, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TestConnectionScreen()));
          }),
          _quickButton(Icons.style_outlined, l10n.actionMyDecks, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyDecksScreen()));
          }),
          _quickButton(Icons.emoji_events_outlined, l10n.actionTopDecks, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RecommendedDecksScreen()));
          }),
          _quickButton(Icons.military_tech_outlined, l10n.actionMatchRecords, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchRecordsScreen()));
          }),
          _quickButton(Icons.location_on_outlined, l10n.actionMeetup, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationHubScreen()));
          }),
        ],
      ),
    );
  }

  Widget _quickButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            width: 55, height: 55,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: AppColors.gold, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildHomeMetaPreview(BuildContext context, MetaState metaState) {
    final l10n = AppLocalizations.of(context);
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
                  Text(l10n.metaTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(width: 6),
                  const Icon(Icons.circle, color: Colors.green, size: 8),
                ],
              ),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MetaEnvironmentScreen())),
                child: Text(l10n.seeMore, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceHigh),
            ),
            child: previewList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text(l10n.metaEmpty, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                  )
                : ListView.separated(
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
                      Expanded(child: Text('${item['name_zh'] ?? l10n.unknownSeries}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
          Icon(icon, color: isActive ? AppColors.gold : Colors.grey, size: 28),
          Text(label, style: TextStyle(fontSize: 10, color: isActive ? AppColors.gold : Colors.grey)),
        ],
      ),
    );
  }
}
