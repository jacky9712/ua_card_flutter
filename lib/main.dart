import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ua_card_flutter/screens/HomeScreen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'repositories/providers.dart';
import 'theme/app_theme.dart';
import 'viewModels/locale_view_model.dart';


// 1. 初始化 Supabase
// lib/main.dart 內修正後的 main()

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String supabaseUrl = '';
  String supabaseAnonKey = '';

  // 1. 在 try 區塊內安全載入與讀取變數
  try {
    await dotenv.load(fileName: "assets/env.txt");
    debugPrint('✅ .env 檔案載入成功');

    // 🔥 只有載入成功，才去讀取 env，這時絕對不會噴 NotInitializedError
    String rawUrl = dotenv.env['SUPABASE_URL'] ?? '';
    String rawKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    supabaseUrl = rawUrl.trim();
    supabaseAnonKey = rawKey.split('#').first.trim();
  } catch (e) {
    debugPrint('🚨 assets/env.txt 讀取失敗。如果是 Web 端，請確認 pubspec.yaml 是否有設定 assets/env.txt 並且執行過 flutter pub get: $e');
  }

  // 2. 安全檢查：如果沒拿到變數，提早攔截阻斷
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('❌ 嚴重錯誤：Supabase URL 或 Anon Key 為空，無法初始化 App！');
    return;
  }

  // 3. 初始化 Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // 4. 訪客無感匿名登入 (使用 Repository 保持一致)
  final savedLocale = await LocaleViewModel.loadSaved();
  final container = ProviderContainer(
    overrides: [savedLocaleProvider.overrideWithValue(savedLocale)],
  );
  final authRepo = container.read(authRepositoryProvider);
  if (authRepo.currentUser == null) {
    try {
      await authRepo.signInAnonymously();
      debugPrint('✅ 訪客匿名登入成功');
    } catch (e) {
      debugPrint('❌ 匿名登入失敗: $e');
    }
  }

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'UA Card Deck Builder',
      debugShowCheckedModeBanner: false,
      // locale 為 null 時跟隨系統；系統語言不在支援清單時退回第一個（繁中）
      locale: ref.watch(localeViewModelProvider),
      // 手動排序：生成的 supportedLocales 是字母序（en 在前），退回預設會變英文
      supportedLocales: const [Locale('zh'), Locale('ja'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 卡牌遊戲風：固定深色底 + 金色點綴。各頁面原本的 isDarkMode 分支
      // 已經用同一組深色色票（0xFF141419 / 0xFF1E1E24 / 0xFF2C2C35），這裡統一收斂。
      theme: buildTcgTheme(),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
