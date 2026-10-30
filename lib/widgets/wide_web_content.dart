import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/wide_web_layout.dart';

/// 寬螢幕網頁時把內容置中並限制最大寬度；其他情況原樣回傳 child，不多包任何一層。
class WideWebContent extends ConsumerWidget {
  const WideWebContent({super.key, required this.child, this.maxWidth = wideWebContentMaxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isWideWebLayout(context, ref)) return child;
    final side = math.max(0.0, (MediaQuery.sizeOf(context).width - maxWidth) / 2);
    return Padding(padding: EdgeInsets.symmetric(horizontal: side), child: child);
  }
}
