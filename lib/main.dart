import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ua_card_flutter/screens/HomeScreen.dart';
import 'screens/test_connection_screen.dart';


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

  // 4. 訪客無感匿名登入
  final supabaseClient = Supabase.instance.client;
  if (supabaseClient.auth.currentUser == null) {
    try {
      await supabaseClient.auth.signInAnonymously();
      debugPrint('✅ 訪客匿名登入成功！UUID: ${supabaseClient.auth.currentUser?.id}');
    } catch (e) {
      debugPrint('❌ 匿名登入失敗: $e');
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UA Card Deck Builder',
      debugShowCheckedModeBanner: false,
      // 這裡直接設定你的主題與首頁
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home:  HomeScreen(), // 進入你的黑金組牌頁面
    );
  }
}