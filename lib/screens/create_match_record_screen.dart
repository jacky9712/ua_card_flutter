// lib/screens/create_match_record_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewModels/deck_view_model.dart';
import '../viewModels/match_record_view_model.dart';
import '../viewModels/opponent_view_model.dart';
import 'create_meetup_post_screen.dart' show kDeckTiers;
import 'qr_scanner_screen.dart';

/// 記錄一場對戰的勝負。可以單獨從「戰績紀錄」畫面進來，也可以帶著
/// [initialMeetupPostId] 從約戰貼文串過來（完全選填，見任務規劃裡的「可串可不串」）。
class CreateMatchRecordScreen extends ConsumerStatefulWidget {
  final int? initialMeetupPostId;

  const CreateMatchRecordScreen({super.key, this.initialMeetupPostId});

  @override
  ConsumerState<CreateMatchRecordScreen> createState() => _CreateMatchRecordScreenState();
}

class _CreateMatchRecordScreenState extends ConsumerState<CreateMatchRecordScreen> {
  String? _selectedOpponentId;
  String? _selectedOpponentName;
  int? _selectedDeckId;
  String? _selectedDeckName;
  String? _selectedTier;
  String _result = 'win';
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _opponentNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // deckViewModelProvider 不像 opponentViewModelProvider 那樣會在 build() 自動抓，
    // 使用者如果沒先逛過「我的牌組」畫面，myDecks 會是空的，這裡手動觸發一次。
    Future.microtask(() => ref.read(deckViewModelProvider.notifier).fetchMyDecks());
  }

  @override
  void dispose() {
    _noteController.dispose();
    _opponentNameController.dispose();
    super.dispose();
  }

  bool _hasOpponent() => _selectedOpponentId != null || _opponentNameController.text.trim().isNotEmpty;

  Future<void> _scanForOpponent() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (!mounted) return;
    // 掃描成功時 opponentViewModelProvider 的清單已經刷新過了，這裡不用特別處理結果，
    // 使用者掃完回來後從下拉選單重新選一次剛加好的對手即可。
  }

  @override
  Widget build(BuildContext context) {
    final opponentState = ref.watch(opponentViewModelProvider);
    final deckState = ref.watch(deckViewModelProvider);
    final matchState = ref.watch(matchRecordViewModelProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('紀錄對戰結果', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('對手', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (opponentState.knownOpponents.isEmpty)
              Text('還沒有已知對手，先掃對方的 QR 名片加一個，或直接在下面輸入名字',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: opponentState.knownOpponents.map((o) {
                  final String id = o['opponent_id'];
                  final String name = o['nickname'] ?? o['profiles']?['display_name'] ?? '（未命名玩家）';
                  final bool selected = _selectedOpponentId == id;
                  return ChoiceChip(
                    label: Text(name),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      // 選已知對手跟自行輸入名字互斥，選一邊要把另一邊清掉，
                      // 避免兩個都填、最後不知道要送哪一個。
                      _selectedOpponentId = id;
                      _selectedOpponentName = name;
                      _opponentNameController.clear();
                    }),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _scanForOpponent,
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('掃 QR 新增對手'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _opponentNameController,
                    enabled: _selectedOpponentId == null,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '或者直接輸入對手名字（沒有帳號也能記）',
                      isDense: true,
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF2C2C35) : const Color(0xFFEFEFF4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                if (_selectedOpponentId != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: '取消已選的對手，改用文字輸入',
                    onPressed: () => setState(() {
                      _selectedOpponentId = null;
                      _selectedOpponentName = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('使用的牌組（選填）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (deckState.myDecks.isEmpty)
              Text('目前沒有已存的牌組', style: TextStyle(color: Colors.grey.shade600, fontSize: 13))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: deckState.myDecks.map((d) {
                  final int id = d['id'];
                  final String name = d['name'] ?? '未命名牌組';
                  final bool selected = _selectedDeckId == id;
                  return ChoiceChip(
                    label: Text(name),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      if (selected) {
                        _selectedDeckId = null;
                        _selectedDeckName = null;
                      } else {
                        _selectedDeckId = id;
                        _selectedDeckName = name;
                      }
                    }),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            const Text('T 級（選填，自己評估這副牌組的強度）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kDeckTiers.map((tier) {
                final bool selected = _selectedTier == tier;
                return ChoiceChip(
                  label: Text(tier),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedTier = selected ? null : tier),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text('結果', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'win', label: Text('勝'), icon: Icon(Icons.emoji_events)),
                ButtonSegment(value: 'loss', label: Text('敗'), icon: Icon(Icons.close)),
                ButtonSegment(value: 'draw', label: Text('平手'), icon: Icon(Icons.remove)),
              ],
              selected: {_result},
              onSelectionChanged: (s) => setState(() => _result = s.first),
            ),
            const SizedBox(height: 20),

            const Text('備註（選填）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '這場對戰的心得、關鍵回合...',
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2C2C35) : const Color(0xFFEFEFF4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            if (matchState.errorMessage != null) ...[
              Text(matchState.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_hasOpponent() && !matchState.isLoading)
                    ? () async {
                        final typedName = _opponentNameController.text.trim();
                        final opponentLabel = _selectedOpponentName ?? typedName;
                        final success = await ref.read(matchRecordViewModelProvider.notifier).createMatchRecord(
                              opponentId: _selectedOpponentId,
                              opponentNameText: _selectedOpponentId == null ? typedName : null,
                              playerDeckId: _selectedDeckId,
                              deckNameSnapshot: _selectedDeckName,
                              deckTier: _selectedTier,
                              result: _result,
                              note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                              meetupPostId: widget.initialMeetupPostId,
                            );
                        if (!mounted) return;
                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('🎉 已記錄與「$opponentLabel」的對戰'), backgroundColor: Colors.green),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: matchState.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('儲存紀錄', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
