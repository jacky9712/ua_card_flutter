// lib/screens/create_meetup_post_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/location_platform.dart';
import '../viewModels/deck_view_model.dart';
import '../viewModels/meetup_view_model.dart';

// Tier1~Tier6 是自評用的，跟「上位卡組推薦」的分級字串同一套慣例，方便畫面共用同一套顏色邏輯。
const List<String> kDeckTiers = ['Tier1', 'Tier2', 'Tier3', 'Tier4', 'Tier5', 'Tier6'];

class CreateMeetupPostScreen extends ConsumerStatefulWidget {
  const CreateMeetupPostScreen({super.key});

  @override
  ConsumerState<CreateMeetupPostScreen> createState() => _CreateMeetupPostScreenState();
}

class _CreateMeetupPostScreenState extends ConsumerState<CreateMeetupPostScreen> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _scheduledAt;
  double? _lat;
  double? _lng;
  bool _isFetchingLocation = false;
  int? _selectedDeckId;
  String? _selectedDeckName;
  String? _selectedTier;

  @override
  void initState() {
    super.initState();
    // deckViewModelProvider 不會自動抓，沒逛過「我的牌組」畫面時 myDecks 會是空的。
    Future.microtask(() => ref.read(deckViewModelProvider.notifier).fetchMyDecks());
  }

  @override
  void dispose() {
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    final position = await getCurrentPositionOrNull();
    if (!mounted) return;
    setState(() => _isFetchingLocation = false);
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法取得目前位置，請確認定位權限已開啟'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() {
      _lat = position.latitude;
      _lng = position.longitude;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已附上目前位置座標'), backgroundColor: Colors.green),
    );
  }

  Future<void> _pickScheduledTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final meetupState = ref.watch(meetupViewModelProvider);
    final deckState = ref.watch(deckViewModelProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('發布約戰地點', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('地點名稱', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              // 送出按鈕是否可按取決於這個欄位有沒有內容，要靠 onChanged 觸發 rebuild，
              // 不然打完字按鈕還是會停在 disabled 狀態，等到別的 state 變化才會「突然」變亮。
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '例如：OO 桌遊店 3 樓',
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2C2C35) : const Color(0xFFEFEFF4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            if (isLocationCapablePlatform)
              OutlinedButton.icon(
                onPressed: _isFetchingLocation ? null : _useCurrentLocation,
                icon: _isFetchingLocation
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_lat != null ? Icons.check_circle : Icons.my_location, size: 18),
                label: Text(_lat != null ? '已附上目前座標' : '附上目前位置座標（選填）'),
              ),
            const SizedBox(height: 20),

            const Text('打算用的牌組（選填）', style: TextStyle(fontWeight: FontWeight.bold)),
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

            const Text('時間', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickScheduledTime,
              icon: const Icon(Icons.event, size: 18),
              label: Text(_scheduledAt == null
                  ? '選擇時間（選填）'
                  : '${_scheduledAt!.year}/${_scheduledAt!.month}/${_scheduledAt!.day} '
                      '${_scheduledAt!.hour.toString().padLeft(2, '0')}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'),
            ),
            const SizedBox(height: 20),

            const Text('備註', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '想約什麼牌組、幾點到幾點...',
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2C2C35) : const Color(0xFFEFEFF4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            if (meetupState.errorMessage != null) ...[
              Text(meetupState.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_locationController.text.trim().isEmpty || meetupState.isLoading)
                    ? null
                    : () async {
                        final name = _locationController.text.trim();
                        if (name.isEmpty) return;
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await ref.read(meetupViewModelProvider.notifier).createMeetupPost(
                              locationName: name,
                              lat: _lat,
                              lng: _lng,
                              note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                              scheduledAt: _scheduledAt,
                              deckId: _selectedDeckId,
                              deckNameSnapshot: _selectedDeckName,
                              deckTier: _selectedTier,
                            );
                        if (!mounted) return;
                        if (success) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('🎉 約戰貼文已發布'), backgroundColor: Colors.green),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: meetupState.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('發布', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
