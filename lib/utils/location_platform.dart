import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// 定位相關功能（即時分享位置、用目前位置排序/發布）的平台判斷閘門。
///
/// 手機優先：Android/iOS 完整支援，Web 讓 geolocator 自己嘗試（瀏覽器會跳權限
/// 詢問，使用者拒絕就拿不到座標，屬於正常的「降級」而不是我們要攔的情況）。
/// 桌面版（Windows/macOS/Linux）Flutter 的定位支援不穩定，直接隱藏這些入口，
/// 比硬做一個常常失敗的功能更誠實——這是計畫裡跟使用者確認過的決策。
bool get isLocationCapablePlatform {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
}

/// 取得目前位置，把「定位服務關閉」「權限被拒」「拿不到座標」全部收斂成 null，
/// 呼叫端只要判斷 null 就好，不用個別 catch 三種不同的例外/狀態。
Future<Position?> getCurrentPositionOrNull() async {
  if (!isLocationCapablePlatform) return null;
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
  } catch (_) {
    return null;
  }
}
