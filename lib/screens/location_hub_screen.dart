// lib/screens/location_hub_screen.dart
import 'package:flutter/material.dart';
import 'meetup_posts_screen.dart';
import 'live_location_screen.dart';

/// 「約戰地點」跟「分享我的位置」共用一個入口，用分頁切換——
/// 避免首頁圖示因為兩個定位相關功能而過度膨脹（跟使用者確認過的設計）。
class LocationHubScreen extends StatelessWidget {
  const LocationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('約戰 / 位置分享', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: '約戰貼文'),
              Tab(text: '即時位置'),
            ],
          ),
        ),
        // MeetupPostsScreen 自己有 Scaffold（含 FAB），這裡直接嵌它的 body 會比較乾淨，
        // 但它是完整 Scaffold widget，用 TabBarView 直接放兩個 Scaffold 也是 Flutter
        // 常見寫法，各自的 FAB/Scaffold 互不干擾。
        body: const TabBarView(
          children: [
            MeetupPostsScreen(),
            LiveLocationScreen(),
          ],
        ),
      ),
    );
  }
}
