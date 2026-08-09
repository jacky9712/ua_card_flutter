import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewModels/profile_view_model.dart';

/// 設定顯示暱稱的小對話框。訪客（匿名）帳號跟正式帳號都能用——
/// 「分享位置」「紀錄勝敗」都需要對方看得懂「這是誰」，匿名帳號原本
/// 完全沒有可辨識的名稱，這個對話框是補上這個缺口的最小可行方案。
class ProfileSetupDialog extends ConsumerStatefulWidget {
  const ProfileSetupDialog({super.key});

  @override
  ConsumerState<ProfileSetupDialog> createState() => _ProfileSetupDialogState();
}

class _ProfileSetupDialogState extends ConsumerState<ProfileSetupDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final current = ref.read(profileViewModelProvider).displayName;
    _controller = TextEditingController(text: current ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
      title: const Text('設定暱稱', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '掃 QR 加對手、約戰貼文、戰績紀錄都會用這個名字讓別人認出你。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 20,
            decoration: const InputDecoration(hintText: '輸入暱稱...', border: OutlineInputBorder()),
          ),
          if (profileState.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(profileState.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          onPressed: profileState.isLoading
              ? null
              : () async {
                  final name = _controller.text.trim();
                  if (name.isEmpty) return;
                  final success = await ref.read(profileViewModelProvider.notifier).updateDisplayName(name);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('暱稱已設為「$name」'), backgroundColor: Colors.green),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
          child: profileState.isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('儲存'),
        ),
      ],
    );
  }
}
