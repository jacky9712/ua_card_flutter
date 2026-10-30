import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 寬螢幕版面的最小視窗寬度。
const double wideWebMinWidth = 1000;

/// 是否為網頁。widget test 的 kIsWeb 固定是 false，測試 override 這個 provider 來走網頁分支。
final isWebPlatformProvider = Provider<bool>((ref) => kIsWeb);

/// 網頁且視窗寬度 >= [wideWebMinWidth] 才用寬螢幕版面。
bool isWideWebLayout(BuildContext context, WidgetRef ref) =>
    ref.watch(isWebPlatformProvider) && MediaQuery.sizeOf(context).width >= wideWebMinWidth;

/// 一般子頁內容的最大寬度。
const double wideWebContentMaxWidth = 960;

/// 單欄表單頁的最大寬度。
const double wideWebFormMaxWidth = 560;

/// 多欄清單頁的最大寬度，跟寬版首頁的內容寬度一致。
const double wideWebListMaxWidth = 1280;

/// 智能組牌寬版的卡片格數：每格至少約 180px，最多 8 欄。
/// 上限也保護「捲動才載入下一頁」：一頁 60 張至少有 8 列，內容一定超過視窗高度。
int wideWebCardGridCount(double width) => ((width - 12) / 188).floor().clamp(3, 8);

/// 推薦牌組寬版的欄數。
int wideWebDeckColumnCount(double width) => width >= wideWebListMaxWidth ? 3 : 2;
