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
