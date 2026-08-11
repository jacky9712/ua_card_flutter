// lib/screens/my_qr_code_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewModels/profile_view_model.dart';
import 'profile_setup_dialog.dart';

/// 顯示自己的個人 QR（格式：`UA_PLAYER|` 後面接使用者 uuid），給其他玩家掃描加為對手用。
/// 沿用 deck_detail_screen.dart 分享牌組 QR 的同一套 qr_flutter 用法。
class MyQrCodeScreen extends ConsumerWidget {
  const MyQrCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileViewModelProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的 QR 名片', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: userId == null
            ? const Text('尚未登入')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profileState.displayName ?? '（尚未設定暱稱）',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: QrImageView(
                        data: 'UA_PLAYER|$userId',
                        version: QrVersions.auto,
                        size: 220.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '讓其他玩家掃描這個 QR，就能把你加為已知對手',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => const ProfileSetupDialog()),
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(profileState.displayName == null ? '設定暱稱' : '編輯暱稱'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
